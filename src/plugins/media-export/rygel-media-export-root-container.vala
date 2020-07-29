/*
 * Copyright (C) 2009-2013 Jens Georg <mail@jensge.org>.
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gee;
using GUPnP;

internal struct Rygel.MediaExport.FolderDefinition {
    string title;
    string definition;
}

// Titles and definitions of some virtual folders,
// for use with QueryContainer.
const Rygel.MediaExport.FolderDefinition[] VIRTUAL_FOLDERS_DEFAULT = {
    { N_("Year"), "dc:date,?" },
    { N_("All"),  "" }
};

// Titles and definitions of virtual folders for Music,
// for use with QueryContainer.
const Rygel.MediaExport.FolderDefinition[] VIRTUAL_FOLDERS_MUSIC = {
    { N_("Artist"), "upnp:artist,?,upnp:album,?" },
    { N_("Album"),  "upnp:album,?" },
    { N_("Genre"),  "dc:genre,?" }
};

/**
 * Represents the root container.
 */
public class Rygel.MediaExport.RootContainer : TrackableDbContainer {
    private Harvester      harvester;
    private Cancellable    cancellable;
    private DBContainer    filesystem_container;
    private ulong          harvester_signal_id;
    private ulong          filesystem_signal_id;

    private static RootContainer instance = null;

    internal const string FILESYSTEM_FOLDER_NAME = N_("Files & Folders");
    internal const string FILESYSTEM_FOLDER_ID   = "Filesystem";

    private const string SEARCH_CONTAINER_PREFIX = QueryContainer.PREFIX +
                                                   "upnp:class," +
                                                   Rygel.MusicItem.UPNP_CLASS +
                                                   ",";

    public static void ensure_exists () throws Error {
        if (RootContainer.instance == null) {
            MediaCache.ensure_exists ();
            RootContainer.instance = new RootContainer ();
        }
    }

    /**
     * Get the single instance of the root container.
     */
    public static RootContainer get_instance () {
        return RootContainer.instance;
    }

    public DBContainer get_filesystem_container () {
        return this.filesystem_container;
    }

    public void shutdown () {
        this.cancellable.cancel ();
    }

    // MediaContainer overrides

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        var object = yield base.find_object (id, cancellable);

        if (object != null) {
            return object;
        }

        if (id.has_prefix (DVDContainer.TRACK_PREFIX)) {
            var parts = id.split (":");
            var parent_id = DVDContainer.PREFIX + ":" + parts[1];
            object = yield base.find_object (parent_id, cancellable);
            var container = object as MediaContainer;
            if (container != null) {
                return yield container.find_object (id, cancellable);
            }

            return null;
        } else  if (id.has_prefix (QueryContainer.PREFIX)) {
            var factory = QueryContainerFactory.get_default ();
            var container = factory.create_from_hashed_id (id);
            if (container != null) {
                container.parent = this;
            }

            return container;
        } else if (id.has_prefix (QueryContainer.ITEM_PREFIX)) {
            var tmp_id = id.replace (QueryContainer.ITEM_PREFIX, "");
            var parts = tmp_id.split (":", 2);
            if (parts.length != 2) {
                return null;
            }

            object = yield base.find_object (parts[1], cancellable);

            if (object == null) {
                return null;
            }

            object.ref_id = object.id;
            object.id = id;

            var factory = QueryContainerFactory.get_default ();
            var container_id = QueryContainer.PREFIX + parts[0];
            var container = factory.create_from_hashed_id (container_id);
            if (container == null) {
                return null;
            }

            object.parent_ref = container;
        }

        return object;
    }

    public override async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                string            sort_criteria,
                                                Cancellable?      cancellable,
                                                out uint          total_matches)
                                                throws GLib.Error {
        if (expression == null) {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      sort_criteria,
                                      cancellable,
                                      out total_matches);
        }

        MediaObjects list;
        MediaContainer query_container = null;
        string upnp_class = null;

        // The rest of this is mainly to deal with the XBox 360's quirkyness
        if (expression is RelationalExpression) {
            // map upnp:class = "object.container.<specificClass>" to the
            // equivalent query container
            var relational_expression = expression as RelationalExpression;

            query_container = this.search_to_virtual_container
                                        (relational_expression);
            upnp_class = relational_expression.operand2;
        } else if (this.is_search_in_virtual_container (expression,
                                                   out query_container)) {
            // do nothing. query_container is set then
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
                                      sort_criteria,
                                      cancellable,
                                      out total_matches);
        }
    }

    // Private methods

    private ArrayList<File> get_shared_uris () {
        ArrayList<string> uris;
        ArrayList<File> actual_uris;

        var config = MetaConfig.get_default ();

        try {
            uris = config.get_string_list ("MediaExport", "uris");
        } catch (Error error) {
            uris = new ArrayList<string> ();
        }

        actual_uris = new ArrayList<File> ((EqualDataFunc<File>) File.equal);

        var home_dir = File.new_for_path (Environment.get_home_dir ());
        unowned string pictures_dir = Environment.get_user_special_dir
                                        (UserDirectory.PICTURES);
        unowned string videos_dir = Environment.get_user_special_dir
                                        (UserDirectory.VIDEOS);
        unowned string music_dir = Environment.get_user_special_dir
                                        (UserDirectory.MUSIC);

        foreach (var uri in uris) {
            var file = File.new_for_commandline_arg (uri);
            if (likely (!file.equal (home_dir))) {
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
                if (file.equal (home_dir)) {
                    continue;
                }
            }

            actual_uris.add (file);
        }

        return actual_uris;
    }

    private MediaContainer? search_to_virtual_container (
                                       RelationalExpression expression) {
        if (expression.operand1 == "upnp:class" &&
            expression.op == SearchCriteriaOp.EQ) {
            string id = SEARCH_CONTAINER_PREFIX;
            switch (expression.operand2) {
                case MediaContainer.MUSIC_ALBUM:
                    id += VIRTUAL_FOLDERS_MUSIC[1].definition;

                    break;
                case MediaContainer.MUSIC_ARTIST:
                    id += VIRTUAL_FOLDERS_MUSIC[0].definition;

                    break;
                case MediaContainer.MUSIC_GENRE:
                    id += VIRTUAL_FOLDERS_MUSIC[2].definition;

                    break;
                case MediaContainer.PLAYLIST:
                    return new PlaylistRootContainer ();
                default:
                    return null;
            }

            var factory = QueryContainerFactory.get_default ();

            return factory.create_from_description_id (id);
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
        MediaContainer query_container;

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

        query_container = this.search_to_virtual_container (left_expression);
        if (query_container == null) {
            query_container = this.search_to_virtual_container (right_expression);
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

        container = factory.create_from_description_id (new_id);

        return true;
    }

    public override int count_children () {
        if (!this.initialized) {
            return 0;
        } else {
            return base.count_children ();
        }
    }

    /**
     * Create a new root container.
     */
    private RootContainer () {
        Object (id : "0",
                title : _("@REALNAME@’s media"),
                parent : null,
                child_count : 0);
    }

    private bool initialized = false;

    public override uint32 get_system_update_id () {
        // Call the base class implementation.
        var id = base.get_system_update_id ();

        // Now we may initialize our container.
        // We waited until now to avoid changing
        // the cached System Update ID before we 
        // have provided it.
        //
        // We do this via an idle handler to avoid
        // delaying Rygel's startup.
        Idle.add (() => {
            try {
                this.init ();
            } catch (Error error) { }

            return false;
        });

        return id;
    }

    private void init () throws Error {
        // This should only be called once.
        if (this.initialized) {
            return;
        }

        this.initialized = true;
        this.cancellable = new Cancellable ();

        // Remove old virtual folders in case virtual folders were disabled
        // during restart or we don't have a particular class of items anymore
        this.media_db.drop_virtual_folders ();

        // Tell the cache about this root container.
        try {
            this.media_db.save_container (this);
        } catch (Error error) { } // do nothing

        // Create a child container to serve the
        // filesystem hierarchy, and tell the cache about it.
        try {
            this.filesystem_container = new TrackableDbContainer
                                        (FILESYSTEM_FOLDER_ID,
                                         _(FILESYSTEM_FOLDER_NAME));
            this.filesystem_container.parent = this;
            this.media_db.save_container (this.filesystem_container);
        } catch (Error error) { }

        // Get the top-level media items or containers known 
        // to the cache from the last service run:
        ArrayList<string> ids;
        try {
            ids = media_db.get_child_ids (FILESYSTEM_FOLDER_ID);
        } catch (Database.DatabaseError e) {
            ids = new ArrayList<string> ();
        }

        // Instantiate the harvester to asynchronously discover
        // media on the filesystem, providing our desired URIs to
        // scan, and react when it has finished its initial scan.
        // It adds all files it finds to the same media cache
        // singleton instance that this class uses.
        this.harvester = new Harvester (this.cancellable,
                                        this.get_shared_uris ());
        this.harvester_signal_id = this.harvester.done.connect
                                        (on_initial_harvesting_done);

        // For each location that we want the harvester to scan,
        // remove it from the cache.
        foreach (var file in this.harvester.locations) {
            ids.remove (MediaCache.get_id (file));
        }

        // Warn about any top-level locations that were known to 
        // the cache (see above) but which we no longer care about,
        // and remove it from the cache.
        foreach (var id in ids) {
            debug ("ID %s is no longer in the configuration. Deleting...", id);
            try {
                // FIXME: I think this needs to emit objDel events...
                this.media_db.remove_by_id (id);
            } catch (Database.DatabaseError error) {
                warning (_("Failed to remove entry: %s"), error.message);
            }
        }

        // Before we start (re-)scanning, create a cache with all mtimes. This
        // is done here in case we removed ids from above so we make sure we
        // re-visit everything.
        this.media_db.rebuild_exists_cache ();

        // Request a rescan of all top-level locations.
        this.harvester.schedule_locations (this.filesystem_container);

        // We have removed some uris so we notify that the root container has
        // changed
        if (!ids.is_empty) {
            this.root_updated ();
        }

        // Subscribe to configuration changes
        MetaConfig.get_default ().setting_changed.connect
                                        (this.on_setting_changed);
    }

    // Signal that the container has been updated with new/changed content.
    private void root_updated () {
        // Emit the "container-updated" signal
        this.updated ();

        // Persist the container_update_id value that was generated by
        // the call to updated().
        try {
            this.media_db.save_container (this);
        } catch (Error error) { }
    }

    private void on_setting_changed (string section, string key) {
        if (section != Plugin.NAME) {
            return;
        }

        if (key == "uris") {
            this.handle_uri_config_change ();
        } else if (key == "virtual-folders") {
            this.handle_virtual_folder_change ();
        }
    }

    private void handle_uri_config_change () {
        var uris = this.get_shared_uris ();
        // Calculate added uris
        var new_uris = new ArrayList<File>
                                    ((EqualDataFunc<File>) File.equal);
        new_uris.add_all (uris);
        new_uris.remove_all (harvester.locations);

        // Calculate removed uris
        var old_uris = new ArrayList<File>
                                    ((EqualDataFunc<File>) File.equal);
        old_uris.add_all (this.harvester.locations);
        old_uris.remove_all (uris);

        foreach (var file in old_uris) {
            // Make sure we're not trying to harvest the removed URI.
            this.harvester.cancel (file);
            try {
                this.media_db.remove_by_id (MediaCache.get_id (file));
            } catch (Database.DatabaseError error) {
                warning (_("Failed to remove entry: %s"), error.message);
            }
        }

        this.harvester.locations.remove_all (old_uris);

        if (!new_uris.is_empty) {
            if (this.filesystem_signal_id != 0) {
                this.filesystem_container.disconnect (this.filesystem_signal_id);
            }
            this.filesystem_signal_id = 0;
            this.harvester_signal_id = this.harvester.done.connect
                                            (on_initial_harvesting_done);
        }

        foreach (var file in new_uris) {
            if (file.query_exists ()) {
                this.harvester.locations.add (file);
                this.harvester.schedule (file, this.filesystem_container);
            }
        }
    }

    private void handle_virtual_folder_change () {
        var virtual_folders = true;
        var config = MetaConfig.get_default ();
        try {
            virtual_folders = config.get_bool (Plugin.NAME, "virtual-folders");
        } catch (Error error) { }

        if (virtual_folders) {
            this.add_default_virtual_folders ();

            return;
        } else {
            this.media_db.drop_virtual_folders ();
        }
        this.root_updated ();
    }

    private void on_initial_harvesting_done () {
        // Disconnect the signal handler.
        this.harvester.disconnect (this.harvester_signal_id);
        this.harvester_signal_id = 0;

        // Some debug output:
        this.media_db.debug_statistics ();

        // Now that the filesystem scanning is done,
        // also add the virtual folders:
        this.add_default_virtual_folders ();

        // Signal that the container has changed:
        this.root_updated ();

        // When the filesystem container changes,
        // re-add the virtual folders, to update them.
        this.filesystem_signal_id =
            this.filesystem_container.container_updated.connect ( () => {
                this.add_default_virtual_folders ();
                this.root_updated ();
            });

    }

    /** Add the default virtual folders,
     * for Music, Pictures, etc,
     * saving them in the cache.
     */
    private void add_default_virtual_folders () {
        var virtual_folders = true;
        var config = MetaConfig.get_default ();
        try {
            virtual_folders = config.get_bool (Plugin.NAME, "virtual-folders");
        } catch (Error error) { }

        if (!virtual_folders) {
            return;
        }

        try {
            this.add_virtual_containers_for_class (_("Music"),
                                                   Rygel.MusicItem.UPNP_CLASS,
                                                   VIRTUAL_FOLDERS_MUSIC);
            this.add_virtual_containers_for_class (_("Pictures"),
                                                   Rygel.PhotoItem.UPNP_CLASS);
            this.add_virtual_containers_for_class (_("Videos"),
                                                   Rygel.VideoItem.UPNP_CLASS);
            this.add_virtual_containers_for_class (_("Playlists"),
                                                   Rygel.PlaylistItem.UPNP_CLASS);
        } catch (Error error) {};
    }

    /**
     * Add a QueryContainer to the provided container,
     * for the specified UPnP class,
     * with the specified definition,
     * saving it in the cache.
     */
    private void add_folder_definition (MediaContainer   container,
                                        string           item_class,
                                        FolderDefinition definition)
                                        throws Error {

        // Create a container ID that contains the virtual folder definition.
        var id = "%supnp:class,%s,%s".printf (QueryContainer.PREFIX,
                                               item_class,
                                               definition.definition);
        if (id.has_suffix (",")) {
            id = id.slice (0,-1);
        }

        // Create a QueryContainer based on the definition in the ID.
        var factory = QueryContainerFactory.get_default ();
        var query_container = factory.create_from_description_id
                                        (id,
                                         _(definition.title));

        // The QueryContainer's constructor has already run some
        // SQL to count the number of items.
        // We remove the container if it has no children.
        //
        // Note that all the virtual folders are re-added anyway
        // when the filesystem changes, so there is no need for
        // the container to exist in case the query would have
        // a non-zero result later.
        if (query_container.child_count > 0) {
            query_container.parent = container;
            this.media_db.save_container (query_container);
        } else {
            this.media_db.remove_by_id (id);
        }
    }

    /**
     * Add a parent container with child containers for the definitions,
     * saving them in the cache.
     */
    private void add_virtual_containers_for_class
                                        (string              parent,
                                         string              item_class,
                                         FolderDefinition[]? definitions = null)
                                         throws Error {
        // Create a container for this virtual folder.
        // We use a NullContainer just because our MediaCache API takes 
        // objects and, after saving the details in the database,
        // it discards the actual container object anyway.
        // 
        // This ID prefix is checked later in ObjectFactory.get_container(),
        // which returns a regular DBContainer instead.
        var container = new NullContainer ("virtual-parent:" + item_class, this, parent);
        this.media_db.save_container (container);

        // Add a child QueryContainer for each of the default definitions.
        foreach (var definition in VIRTUAL_FOLDERS_DEFAULT) {
            this.add_folder_definition (container, item_class, definition);
        }

        // Add a child QueryContainer for each of the additional specified definitions.
        if (definitions != null) {
            foreach (var definition in definitions) {
                this.add_folder_definition (container, item_class, definition);
            }
        }

        // If no child QueryContainers were added, remove
        // the provided parent container. Unless it's the Playlist container.
        if (this.media_db.get_child_count (container.id) == 0 &&
            !container.id.has_prefix ("virtual-parent:" +
                                      Rygel.PlaylistItem.UPNP_CLASS)) {
            this.media_db.remove_by_id (container.id);
        } else {
            container.updated ();
        }
    }
}
