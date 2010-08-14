/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using Gee;
using GUPnP;

internal struct Rygel.MediaExport.FolderDefinition {
    string title;
    string definition;
}

const Rygel.MediaExport.FolderDefinition[] virtual_folders_default = {
    { N_("Year"), "dc:date,?" },
    { N_("All"),  "" }
};

const Rygel.MediaExport.FolderDefinition[] virtual_folders_music = {
    { N_("Artist"), "upnp:artist,?,upnp:album,?" },
    { N_("Album"),  "upnp:album,?" },
    { N_("Genre"),  "dc:genre,?" }
};

/**
 * Represents the root container.
 */
public class Rygel.MediaExport.RootContainer : Rygel.MediaExport.DBContainer {
    private DBusService service;
    private Harvester harvester;

    private static MediaContainer instance = null;

    public static MediaContainer get_instance () {
        if (RootContainer.instance == null) {
            try {
                RootContainer.instance = new RootContainer ();
            } catch (Error error) {
                warning (_("Failed to create instance of database"));
                RootContainer.instance = new NullContainer ();
            }
        }

        return RootContainer.instance;
    }

    // DBus utility methods

    public void add_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        this.harvester.schedule (file, this, "DBUS");
    }

    public void remove_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        var id = MediaCache.get_id (file);

        this.harvester.cancel (file);
        try {
            this.media_db.remove_by_id (id);
        } catch (Error error) {
            warning (_("Failed to remove URI: %s"), error.message);
        }
    }

    public string[] get_dynamic_uris () {
        try {
            var uris = this.media_db.get_flagged_uris ("DBUS");

            return uris.to_array ();
        } catch (Error error) { }

        return new string[0];
    }

    // MediaContainer overrides

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        var object = yield base.find_object (id, cancellable);

        if (object == null && id.has_prefix (QueryContainer.PREFIX)) {
            var container = new QueryContainer (this.media_db, id);
            container.parent = this;

            return container;
        }

        return object;
    }

    public override async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                out uint          total_matches,
                                                Cancellable?      cancellable)
                                                throws GLib.Error {
         if (expression == null) {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      cancellable);
        }

        MediaObjects list;
        MediaContainer query_container = null;
        string upnp_class = null;

        if (expression is RelationalExpression) {
            var relational_expression = expression as RelationalExpression;

            query_container = search_to_virtual_container (
                                        relational_expression);
            upnp_class = relational_expression.operand2;
        } else if (is_search_in_virtual_container (expression,
                                                   out query_container)) {
            // do nothing. query_container is filled then
        }

        if (query_container != null) {
            list = yield query_container.get_children (offset,
                                                       max_count,
                                                       cancellable);
            // FIXME: This is wrong
            total_matches = list.size;

            if (upnp_class != null) {
                foreach (var object in list) {
                    object.upnp_class = upnp_class;
                }
            }

            return list;
        } else {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      cancellable);
        }
    }



    private ArrayList<string> get_uris () {
        ArrayList<string> uris;

        var config = MetaConfig.get_default ();

        try {
            uris = config.get_string_list ("MediaExport", "uris");
        } catch (Error error) {
            uris = new ArrayList<string> ();
        }

        try {
            uris.add_all (this.media_db.get_flagged_uris ("DBUS"));
        } catch (Error error) {}

        return uris;
    }

    private QueryContainer? search_to_virtual_container (
                                       RelationalExpression expression) {
        if (expression.operand1 == "upnp:class" &&
            expression.op == SearchCriteriaOp.EQ) {
            switch (expression.operand2) {
                case "object.container.album.musicAlbum":
                    string id = "virtual-container:upnp:album,?";
                    QueryContainer.register_id (ref id);

                    return new QueryContainer (this.media_db,
                                               id,
                                               _("Albums"));

                case "object.container.person.musicArtist":
                    string id = "virtual-container:dc:creator,?,upnp:album,?";
                    QueryContainer.register_id (ref id);

                    return new QueryContainer (this.media_db,
                                               id,
                                               _("Artists"));
                default:
                    return null;
            }
        }

        return null;
    }

    /**
     * Check if a passed search expression is a simple search in a virtual
     * container.
     *
     * @param expression the expression to check
     * @param new_id contains the id of the virtual container constructed from
     *               the search
     * @param upnp_class contains the class of the container the search was
     *                   looking in
     * @return true if it was a search in virtual container, false otherwise.
     * @note This works single level only. Enough to satisfy Xbox music
     *       browsing, but may need refinement
     */
    private bool is_search_in_virtual_container (
                                        SearchExpression   expression,
                                        out MediaContainer container) {
        RelationalExpression virtual_expression = null;
        QueryContainer query_container;

        if (!(expression is LogicalExpression)) {
            return false;
        }

        var logical_expression = expression as LogicalExpression;

        if (!(logical_expression.operand1 is RelationalExpression &&
            logical_expression.operand2 is RelationalExpression &&
            logical_expression.op == LogicalOperator.AND)) {

            return false;
        }

        var left_expression = logical_expression.operand1 as RelationalExpression;
        var right_expression = logical_expression.operand2 as RelationalExpression;

        query_container = search_to_virtual_container (left_expression);
        if (query_container == null) {
            query_container = search_to_virtual_container (right_expression);
            if (query_container != null) {
                virtual_expression = left_expression;
            } else {
                return false;
            }
        } else {
            virtual_expression = right_expression;
        }

        var last_argument = query_container.plaintext_id.replace (
                                        QueryContainer.PREFIX,
                                        "");

        var escaped_detail = Uri.escape_string (virtual_expression.operand2,
                                                "",
                                                true);
        var new_id = "%s%s,%s,%s".printf (QueryContainer.PREFIX,
                                          virtual_expression.operand1,
                                          escaped_detail,
                                          last_argument);

        QueryContainer.register_id (ref new_id);
        container = new QueryContainer (this.media_db, new_id);

        return true;
    }


    /**
     * Create a new root container.
     */
    private RootContainer () throws Error {
        var db = MediaCache.get_default ();

        base (db, "0", "MediaExportRoot");

        this.harvester = new Harvester ();

        try {
            this.service = new DBusService (this);
        } catch (Error err) {
            warning (_("Failed to create MediaExport DBus service: %s"),
                     err.message);
        }

        try {
            this.media_db.save_container (this);
        } catch (Error error) { } // do nothing

        ArrayList<string> ids;
        try {
            ids = media_db.get_child_ids ("0");
        } catch (DatabaseError e) {
            ids = new ArrayList<string> ();
        }

        var uris = get_uris ();
        foreach (var uri in uris) {
            var file = File.new_for_commandline_arg (uri);
            if (file.query_exists (null)) {
                ids.remove (MediaCache.get_id (file));
                this.harvester.schedule (file, this);
            }
        }

        try {
            var config = MetaConfig.get_default ();
            var virtual_containers = config.get_string_list (
                                        "MediaExport",
                                        "virtual-folders");
            foreach (var container in virtual_containers) {
                var info = container.split ("=");
                var id = QueryContainer.PREFIX + info[1];
                if (!QueryContainer.validate_virtual_id (id)) {
                    warning (_("%s is not a valid virtual ID"), id);

                    continue;
                }
                QueryContainer.register_id (ref id);

                var virtual_container = new QueryContainer (
                                        this.media_db,
                                        id,
                                        info[0]);
                virtual_container.parent = this;
                try {
                    this.media_db.save_container (virtual_container);
                } catch (Error error) { } // do nothing

                ids.remove (id);
            }
        } catch (Error error) {
            warning (_("Got error while trying to find virtual folders: %s"),
                     error.message);
        }

        foreach (var id in ids) {
            debug (_("ID %s no longer in config, deleting..."), id);
            try {
                this.media_db.remove_by_id (id);
            } catch (DatabaseError error) {
                warning (_("Failed to remove entry: %s"), error.message);
            }
        }

        this.add_default_virtual_folders ();

        this.updated ();
    }

    private void add_default_virtual_folders () {
        try {
            this.add_virtual_containers_for_class (_("Music"),
                                                   "object.item.audioItem",
                                                    virtual_folders_music);
            this.add_virtual_containers_for_class (_("Pictures"),
                                                   "object.item.imageItem");
            this.add_virtual_containers_for_class (_("Videos"),
                                                   "object.item.videoItem");
        } catch (Error error) {};
    }

    private void add_folder_definition (MediaContainer   container,
                                        string           item_class,
                                        FolderDefinition definition)
                                        throws Error {
        var id = "%supnp:class,%s,%s".printf (QueryContainer.PREFIX,
                                               item_class,
                                               definition.definition);
        if (id.has_suffix (",")) {
            id = id.slice (0,-1);
        }

        QueryContainer.register_id (ref id);
        var query_container = new QueryContainer (this.media_db,
                                                  id,
                                                  definition.title);
        query_container.parent = container;
        this.media_db.save_container (query_container);
    }

    private void add_virtual_containers_for_class (
                                        string              parent,
                                        string              item_class,
                                        FolderDefinition[]? definitions = null)
                                        throws Error {
        var container = new NullContainer ();
        container.parent = this;
        container.title = parent;
        container.id = "virtual-parent:" + item_class;
        this.media_db.save_container (container);

        foreach (var definition in virtual_folders_default) {
            this.add_folder_definition (container, item_class, definition);
        }

        if (definitions != null) {
            foreach (var definition in definitions) {
                this.add_folder_definition (container, item_class, definition);
            }
        }
    }
}
