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

/**
 * Represents the root container.
 */
public class Rygel.MediaExport.RootContainer : Rygel.MediaExport.DBContainer {
    private MetadataExtractor extractor;
    private HashMap<File, Harvester> harvester;
    private RecursiveFileMonitor monitor;
    private DBusService service;
    private DynamicContainer dynamic_elements;
    private Gee.List<Harvester> harvester_trash;

    private static MediaContainer instance = null;

    private ArrayList<string> get_uris () {
        ArrayList<string> uris;

        var config = MetaConfig.get_default ();

        try {
            uris = config.get_string_list ("MediaExport", "uris");
        } catch (Error error) {
            uris = new ArrayList<string> ();
        }

        // either an error occured or the gconf key is not set
        if (uris.size == 0) {
            debug (_("Nothing configured, using XDG special folders"));
            UserDirectory[] xdg_directories = { UserDirectory.MUSIC,
                                                UserDirectory.PICTURES,
                                                UserDirectory.VIDEOS };
            foreach (var directory in xdg_directories) {
                var uri = Environment.get_user_special_dir (directory);
                if (uri != null) {
                    uris.add (uri);
                }
            }
        }

        var dbus_uris = this.dynamic_elements.get_uris ();
        if (dbus_uris != null) {
            uris.add_all (dbus_uris);
        }

        return uris;
    }

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

    public void add_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        this.harvest (file, this.dynamic_elements);
    }

    public void remove_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        var id = Checksum.compute_for_string (ChecksumType.MD5,
                                              file.get_uri ());

        try {
            this.media_db.remove_by_id (id);
        } catch (Error error) {
            warning (_("Failed to remove URI: %s"), error.message);
        }
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
     * Check if the passed search expression is a simple find_object
     * operation.
     * (@id = id)
     *
     * @param search_expression expression to test
     * @param id containts id of container on successful return
     * @return true if expression was a find object
     */
    private bool is_find_object (SearchExpression search_expression,
                                 out string       id) {
        if (!(search_expression is RelationalExpression)) {
            return false;
        }

        var expression = search_expression as RelationalExpression;
        id = expression.operand2;

        return (expression.operand1 == "@id" &&
                expression.op == SearchCriteriaOp.EQ);
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

    public override async Gee.List<MediaObject>? search (
                                        SearchExpression expression,
                                        uint             offset,
                                        uint             max_count,
                                        out uint         total_matches,
                                        Cancellable?     cancellable)
                                        throws GLib.Error {
        Gee.List<MediaObject> list;
        MediaContainer query_container = null;
        string id;
        string upnp_class = null;

        if (is_find_object (expression, out id) &&
            id.has_prefix (QueryContainer.PREFIX)) {
            query_container = new QueryContainer (this.media_db, id);
            query_container.parent = this;

            list = new ArrayList<MediaObject> ();
            list.add (query_container);
            total_matches = list.size;

            return list;
        }

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


    public string[] get_dynamic_uris () {
        var dynamic_uris = this.dynamic_elements.get_uris ();

        return dynamic_uris.to_array ();
    }


    /**
     * Create a new root container.
     */
    private RootContainer () throws Error {
        var object_factory = new ObjectFactory ();
        var db = new MediaCache.with_factory ("media-export", object_factory);

        base (db, "0", "MediaExportRoot");

        this.extractor = new MetadataExtractor ();

        this.harvester = new HashMap<File, Harvester> (file_hash, file_equal);
        this.harvester_trash = new ArrayList<Harvester> ();

        this.monitor = new RecursiveFileMonitor (null);
        this.monitor.changed.connect (this.on_file_changed);

        try {
            this.service = new DBusService (this);
        } catch (Error err) {
            warning (_("Failed to create MediaExport DBus service: %s"),
                     err.message);
        }
        this.dynamic_elements = new DynamicContainer (db, this);

        try {
            int64 timestamp;
            if (!this.media_db.exists ("0", out timestamp)) {
                media_db.save_container (this);
            }

            if (!this.media_db.exists ("DynamicContainerId", out timestamp)) {
                media_db.save_container (this.dynamic_elements);
            }
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
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      file.get_uri ());
                ids.remove (id);
                this.harvest (file);
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
            if (id == DynamicContainer.ID) {
                continue;
            }

            debug (_("ID %s no longer in config, deleting..."), id);
            try {
                this.media_db.remove_by_id (id);
            } catch (DatabaseError error) {
                warning (_("Failed to remove entry: %s"), error.message);
            }
        }

        this.updated ();
    }

    private void on_file_harvested (Harvester harvester,
                                    File      file) {
        message (_("'%s' harvested"), file.get_uri ());

        this.harvester.remove (file);
    }

    private void on_remove_cancelled_harvester (Harvester harvester,
                                                File      file) {
        this.harvester_trash.remove (harvester);
    }

    private void harvest (File file, MediaContainer parent = this) {
        if (this.extractor == null) {
            warning (_("No Metadata extractor available. Will not crawl"));

            return;
        }

        if (this.harvester.contains (file)) {
            debug (_("Already harvesting; cancelling"));
            var harvester = this.harvester[file];
            harvester.harvested.disconnect (this.on_file_harvested);
            harvester.cancellable.cancel ();
            harvester.harvested.connect (this.on_remove_cancelled_harvester);
            this.harvester_trash.add (harvester);
        }

        var harvester = new Harvester (parent,
                                       this.media_db,
                                       this.extractor,
                                       this.monitor);
        harvester.harvested.connect (this.on_file_harvested);
        this.harvester[file] = harvester;
        harvester.harvest (file);
    }

    private void on_file_changed (File             file,
                                  File?            other,
                                  FileMonitorEvent event) {
        switch (event) {
            case FileMonitorEvent.CREATED:
            case FileMonitorEvent.CHANGES_DONE_HINT:
                debug (_("Trying to harvest %s because of %d"),
                       file.get_uri (),
                       event);
                var parent = file.get_parent ();
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      parent.get_uri ());
                try {
                    var parent_container = this.media_db.get_object (id)
                                           as MediaContainer;
                    assert (parent_container != null);

                    this.harvest (file, parent_container);
                } catch (DatabaseError error) {
                    warning (_("Error fetching object '%s' from database: %s"),
                             id,
                             error.message);
                }
                break;
            case FileMonitorEvent.DELETED:
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      file.get_uri ());

                try {
                    // the full object is fetched instead of simply calling
                    // exists because we need the parent to signalize the
                    // change
                    var obj = this.media_db.get_object (id);

                    // it may be that files removed are files that are not
                    // in the database, because they're not media files
                    if (obj != null) {
                        this.media_db.remove_object (obj);
                        if (obj.parent != null) {
                            obj.parent.updated ();
                        }
                    }
                } catch (Error error) {
                    warning (_("Error removing object from database: %s"),
                             error.message);
                }
                break;
            default:
                break;
        }
    }
}
