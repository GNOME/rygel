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

const Rygel.MediaExport.FolderDefinition[] VIRTUAL_FOLDERS_DEFAULT = {
    { N_("Year"), "dc:date,?" },
    { N_("All"),  "" }
};

const Rygel.MediaExport.FolderDefinition[] VIRTUAL_FOLDERS_MUSIC = {
    { N_("Artist"), "upnp:artist,?,upnp:album,?" },
    { N_("Album"),  "upnp:album,?" },
    { N_("Genre"),  "dc:genre,?" }
};

/**
 * Represents the root container.
 */
public class Rygel.MediaExport.RootContainer : Rygel.MediaExport.DBContainer {
    private DBusService    service;
    private Harvester      harvester;
    private Cancellable    cancellable;
    private MediaContainer filesystem_container;
    private ulong          harvester_signal_id;

    private static MediaContainer instance = null;
    private static Error          creation_error = null;

    internal const string FILESYSTEM_FOLDER_NAME = N_("Files & Folders");
    internal const string FILESYSTEM_FOLDER_ID   = "Filesystem";

    private const string SEARCH_CONTAINER_PREFIX = QueryContainer.PREFIX +
                                                   "upnp:class," +
                                                   Rygel.MusicItem.UPNP_CLASS +
                                                   ",";

    public static MediaContainer get_instance () throws Error {
        if (RootContainer.instance == null) {
            try {
                RootContainer.instance = new RootContainer ();
            } catch (Error error) {
                // cache error for further calls and create Null container
                RootContainer.instance = new NullContainer ();
                RootContainer.creation_error = error;
            }
        } else {
            if (creation_error != null) {
                throw creation_error;
            }
        }

        return RootContainer.instance;
    }

    public MediaContainer get_filesystem_container () {
        return this.filesystem_container;
    }

    public void shutdown () {
        this.cancellable.cancel ();
    }

    // DBus utility methods

    public void add_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        this.harvester.schedule (file,
                                 this.filesystem_container,
                                 "DBUS");
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
            var factory = QueryContainerFactory.get_default ();
            var container = factory.create_from_id (this.media_db, id);
            if (container != null) {
                container.parent = this;
            }

            return container;
        }

        return object;
    }

    public override async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                out uint          total_matches,
                                                string            sort_criteria,
                                                Cancellable?      cancellable)
                                                throws GLib.Error {
         if (expression == null) {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      sort_criteria,
                                      cancellable);
        }

        MediaObjects list;
        MediaContainer query_container = null;
        string upnp_class = null;

        if (expression is RelationalExpression) {
            var relational_expression = expression as RelationalExpression;

            query_container = search_to_virtual_container
                                        (relational_expression);
            upnp_class = relational_expression.operand2;
        } else if (is_search_in_virtual_container (expression,
                                                   out query_container)) {
            // do nothing. query_container is filled then
        }

        if (query_container != null) {
            list = yield query_container.get_children (offset,
                                                       max_count,
                                                       sort_criteria,
                                                       cancellable);
            total_matches = query_container.child_count;

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
                                      sort_criteria,
                                      cancellable);
        }
    }



    private ArrayList<File> get_shared_uris () {
        ArrayList<string> uris;
        ArrayList<File> actual_uris;

        var config = MetaConfig.get_default ();

        try {
            uris = config.get_string_list ("MediaExport", "uris");
        } catch (Error error) {
            uris = new ArrayList<string> ();
        }

        try {
            uris.add_all (this.media_db.get_flagged_uris ("DBUS"));
        } catch (Error error) {}

        actual_uris = new ArrayList<File> ();

        var home_dir = File.new_for_path (Environment.get_home_dir ());
        unowned string pictures_dir = Environment.get_user_special_dir
                                        (UserDirectory.PICTURES);
        unowned string videos_dir = Environment.get_user_special_dir
                                        (UserDirectory.VIDEOS);
        unowned string music_dir = Environment.get_user_special_dir
                                        (UserDirectory.MUSIC);

        foreach (var uri in uris) {
            var file = File.new_for_commandline_arg (uri);
            if (likely (file != home_dir)) {
                var actual_uri = uri;

                if (likely (pictures_dir != null)) {
                    actual_uri = actual_uri.replace ("@PICTURES@", pictures_dir);
                }
                if (likely (videos_dir != null)) {
                    actual_uri = actual_uri.replace ("@VIDEOS@", videos_dir);
                }
                if (likely (music_dir != null)) {
                    actual_uri = actual_uri.replace ("@MUSIC@", music_dir);
                }

                // protect against special directories expanding to $HOME
                file = File.new_for_commandline_arg (actual_uri);
                if (file == home_dir) {
                    continue;
                }
            }

            actual_uris.add (file);
        }

        return actual_uris;
    }

    private QueryContainer? search_to_virtual_container (
                                       RelationalExpression expression) {
        if (expression.operand1 == "upnp:class" &&
            expression.op == SearchCriteriaOp.EQ) {
            string id = SEARCH_CONTAINER_PREFIX;
            switch (expression.operand2) {
                case "object.container.album.musicAlbum":
                    id += "upnp:album,?";

                    break;
                case "object.container.person.musicArtist":
                    id += "dc:creator,?,upnp:album,?";

                    break;
                case "object.container.genre.musicGenre":
                    id += "dc:genre,?";

                    break;
                default:
                    return null;
            }

            var factory = QueryContainerFactory.get_default ();

            return factory.create_from_description (this.media_db, id);
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
    private bool is_search_in_virtual_container (SearchExpression   expression,
                                                 out MediaContainer container) {
        RelationalExpression virtual_expression = null;
        QueryContainer query_container;

        container = null;

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

        var factory = QueryContainerFactory.get_default ();
        var plaintext_id = factory.get_virtual_container_definition
                                        (query_container.id);

        var last_argument = plaintext_id.replace (QueryContainer.PREFIX, "");

        var escaped_detail = Uri.escape_string (virtual_expression.operand2,
                                                "",
                                                true);
        var new_id = "%s%s,%s,%s".printf (QueryContainer.PREFIX,
                                          virtual_expression.operand1,
                                          escaped_detail,
                                          last_argument);

        container = factory.create_from_description (this.media_db,
                                                     new_id);

        return true;
    }


    /**
     * Create a new root container.
     */
    private RootContainer () throws Error {
        var db = MediaCache.get_default ();

        base (db, "0", _("@REALNAME@'s media"));

        this.cancellable = new Cancellable ();

        try {
            this.service = new DBusService (this);
        } catch (Error err) {
            warning (_("Failed to create MediaExport D-Bus service: %s"),
                     err.message);
        }

        try {
            this.media_db.save_container (this);
        } catch (Error error) { } // do nothing

        try {
            this.filesystem_container = new DBContainer
                                        (media_db,
                                         FILESYSTEM_FOLDER_ID,
                                         _(FILESYSTEM_FOLDER_NAME));
            this.filesystem_container.parent = this;
            this.media_db.save_container (this.filesystem_container);
        } catch (Error error) { }

        ArrayList<string> ids;
        try {
            ids = media_db.get_child_ids (FILESYSTEM_FOLDER_ID);
        } catch (DatabaseError e) {
            ids = new ArrayList<string> ();
        }

        this.harvester = new Harvester (this.cancellable,
                                        this.get_shared_uris ());
        this.harvester_signal_id = this.harvester.done.connect
                                        (on_initial_harvesting_done);

        foreach (var file in this.harvester.locations) {
            ids.remove (MediaCache.get_id (file));
            this.harvester.schedule (file,
                                     this.filesystem_container);
        }

        foreach (var id in ids) {
            debug ("ID %s no longer in config; deleting...", id);
            try {
                this.media_db.remove_by_id (id);
            } catch (DatabaseError error) {
                warning (_("Failed to remove entry: %s"), error.message);
            }
        }

        this.updated ();
    }

    private void on_initial_harvesting_done () {
        this.harvester.disconnect (this.harvester_signal_id);
        this.media_db.debug_statistics ();
        this.add_default_virtual_folders ();
        this.updated ();

        this.filesystem_container.container_updated.connect( () => {
            this.add_default_virtual_folders ();
            this.updated ();
        });
    }

    private void add_default_virtual_folders () {
        try {
            this.add_virtual_containers_for_class (_("Music"),
                                                   Rygel.MusicItem.UPNP_CLASS,
                                                   VIRTUAL_FOLDERS_MUSIC);
            this.add_virtual_containers_for_class (_("Pictures"),
                                                   Rygel.PhotoItem.UPNP_CLASS);
            this.add_virtual_containers_for_class (_("Videos"),
                                                   Rygel.VideoItem.UPNP_CLASS);
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

        var factory = QueryContainerFactory.get_default ();
        var query_container = factory.create_from_description
                                        (this.media_db,
                                         id,
                                         _(definition.title));

        if (query_container.child_count > 0) {
            query_container.parent = container;
            this.media_db.save_container (query_container);
        } else {
            this.media_db.remove_by_id (id);
        }
    }

    private void add_virtual_containers_for_class
                                        (string              parent,
                                         string              item_class,
                                         FolderDefinition[]? definitions = null)
                                         throws Error {
        var container = new NullContainer ();
        container.parent = this;
        container.title = parent;
        container.id = "virtual-parent:" + item_class;
        this.media_db.save_container (container);

        foreach (var definition in VIRTUAL_FOLDERS_DEFAULT) {
            this.add_folder_definition (container, item_class, definition);
        }

        if (definitions != null) {
            foreach (var definition in definitions) {
                this.add_folder_definition (container, item_class, definition);
            }
        }

        if (this.media_db.get_child_count (container.id) == 0) {
            this.media_db.remove_by_id (container.id);
        } else {
            container.updated ();
        }
    }
}
