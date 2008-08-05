/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using CStuff;

public class GUPnP.MediaManager : GLib.Object, MediaProvider {
    private DIDLLiteWriter didl_writer;

    /* Properties */
    public string# root_id { get; construct; }
    public string# root_parent_id { get; construct; }
    public string# title { get; private construct; }
    public GUPnP.Context context { get; construct; }
    public uint32 system_update_id { get; private set; }

    /* HashTable of Media Providers
     * keys -> root-id assigned to Media Provider
     * values -> Media Provider objects
     */
    HashTable<string, MediaProvider> providers;

    /* We need to keep the modules somewhere */
    List<Module> modules;

    private delegate MediaProvider RegisterMediaProviderFunc
                                    (string        root_id,
                                     string        root_parent_id,
                                     GUPnP.Context context);

    construct {
        this.providers = new HashTable<string, MediaProvider>
                                ((HashFunc) id_hash_func,
                                 (EqualFunc) is_root_equal);
        this.modules = new List<Module> ();
        this.didl_writer = new DIDLLiteWriter ();

        this.system_update_id = 0;

        this.register_media_providers ();
    }

    /* Pubic methods */
    public MediaManager (GUPnP.Context context) {
        this.root_id = "0";
        this.root_parent_id = "-1";
        this.title = "Media Manager";
        this.context = context;
    }

    public string? browse (string   container_id,
                           string   filter,
                           uint     starting_index,
                           uint     requested_count,
                           string   sort_criteria,
                           out uint number_returned,
                           out uint total_matches,
                           out uint update_id) {
        string didl;

        string root_id = this.get_root_id_from_id (container_id);

        if (root_id == this.root_id) {
            didl = this.browse_root_container (out number_returned,
                                               out total_matches,
                                               out update_id);
        } else {
            weak MediaProvider provider = this.providers.lookup (root_id);
            if (provider != null) {
                didl = provider.browse (container_id,
                                        filter,
                                        starting_index,
                                        requested_count,
                                        sort_criteria,
                                        out number_returned,
                                        out total_matches,
                                        out update_id);

                if (update_id == uint32.MAX) {
                    update_id = this.system_update_id;
                }
            } else {
                didl = null;
            }
        }

        return didl;
    }

    public string get_metadata (string  object_id,
                                string  filter,
                                string  sort_criteria,
                                out uint update_id) {
        string didl;

        string root_id = this.get_root_id_from_id (object_id);

        if (root_id == this.root_id) {
            didl = this.get_root_container_metadata (out update_id);
        } else {
            weak MediaProvider provider = this.providers.lookup (root_id);
            if (provider != null) {
                didl = provider.get_metadata (object_id,
                                              filter,
                                              sort_criteria,
                                              out update_id);
                if (update_id == uint32.MAX) {
                    update_id = this.system_update_id;
                }
            } else {
                didl = null;
            }
        }

        return didl;
    }

    public uint get_root_children_count () {
        return this.providers.size ();
    }

    /* Private methods */
    private string browse_root_container (out uint number_returned,
                                          out uint total_matches,
                                          out uint update_id) {
        /* Start DIDL-Lite fragment */
        this.didl_writer.start_didl_lite (null, null, true);

        this.providers.for_each ((key, value) => {
            MediaProvider provider = (MediaProvider) value;

            add_container ((string) key,
                           this.root_id,
                           provider.title,
                           provider.get_root_children_count ());
            });

        number_returned = total_matches = this.get_root_children_count ();

        /* End DIDL-Lite fragment */
        this.didl_writer.end_didl_lite ();

        /* Retrieve generated string */
        string didl = this.didl_writer.get_string ();

        /* Reset the parser state */
        this.didl_writer.reset ();

        update_id = this.system_update_id;

        return didl;
    }

    private string get_root_container_metadata (out uint update_id) {
        /* Start DIDL-Lite fragment */
        this.didl_writer.start_didl_lite (null, null, true);

        add_container (this.root_id,
                       "-1",         /* FIXME */
                       this.title,
                       this.get_root_children_count ());

        /* End DIDL-Lite fragment */
        this.didl_writer.end_didl_lite ();

        /* Retrieve generated string */
        string didl = this.didl_writer.get_string ();

        /* Reset the parser state */
        this.didl_writer.reset ();

        update_id = this.system_update_id;

        return didl;
    }

    private void add_container (string id,
                                string parent_id,
                                string title,
                                uint   child_count) {
        this.didl_writer.start_container (id,
                                          parent_id,
                                          (int) child_count,
                                          false,
                                          false);

        this.didl_writer.add_string ("class",
                                     DIDLLiteWriter.NAMESPACE_UPNP,
                                     null,
                                     "object.container.storageFolder");

        this.didl_writer.add_string ("title",
                                     DIDLLiteWriter.NAMESPACE_DC,
                                     null,
                                     title);

        /* End of Container */
        this.didl_writer.end_container ();
    }

    string get_root_id_from_id (string id) {
        string[] tokens;

        tokens = id.split (":", 2);

        return tokens[0];
    }

    private static uint id_hash_func (string id) {
        return id[0];
    }

    private static bool is_root_equal (string id1, string id2) {
        string[] id1_tokens = id1.split (":", 2);
        string[] id2_tokens = id2.split (":", 2);

        return id1_tokens[0] == id2_tokens[0];
    }

    // Plugin loading functions

    private void register_media_providers () {
        assert (Module.supported());

        File dir = File.new_for_path (BuildConfig.PLUGIN_DIR);
        assert (dir != null && is_dir (dir));

        this.register_media_provider_from_dir (dir);
    }

    private void register_media_provider_from_dir (File dir) {
        FileEnumerator enumerator;

        try {
            string attributes = FILE_ATTRIBUTE_STANDARD_NAME + "," +
                                FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                                FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
            enumerator = dir.enumerate_children (attributes,
                                                 FileQueryInfoFlags.NONE,
                                                 null);
        } catch (Error error) {
            critical ("Error listing contents of directory '%s': %s\n",
                      dir.get_path (),
                      error.message);

            return;
        }

        FileInfo info;

        try {
            while ((info = enumerator.next_file (null)) != null) {
                string file_name = info.get_name ();
                string file_path = Path.build_filename (dir.get_path (),
                                                        file_name);
                File file = File.new_for_path (file_path);
                FileType file_type = info.get_file_type ();
                string content_type = info.get_content_type ();
                weak string mime = g_content_type_get_mime_type (content_type);

                if (file_type == FileType.DIRECTORY) {
                    // Recurse into directories
                    this.register_media_provider_from_dir (file);
                } else if (mime == "application/x-sharedlib") {
                    // Seems like we found a plugin
                    this.register_media_provider_from_file (file_path);
                }
            }
        } catch (Error error) {
            critical ("Error iterating contents of directory '%s': %s\n",
                      dir.get_path (),
                      error.message);
        }
    }

    private void register_media_provider_from_file (string file_path) {
        MediaProvider provider;
        Module module;

        provider = this.load_media_provider_from_file (file_path, out module);
        if (provider != null) {
            this.providers.insert (provider.root_id, provider);
            this.modules.append (#module);
        }
    }

    private MediaProvider? load_media_provider_from_file (string     file_path,
                                                          out Module module) {
        module = Module.open (file_path, ModuleFlags.BIND_LOCAL);
        if (module == null) {
            debug ("Failed to load plugin from path: '%s'\n", file_path);

            return null;
        }

        void* function;
        RegisterMediaProviderFunc register_media_provider;

        module.symbol("register_media_provider", out function);

        register_media_provider = (RegisterMediaProviderFunc) function;

        if (register_media_provider == null) {
            warning ("Failed to load plugin from path: '%s'\n", file_path);

            return null;
        }

        debug ("Loaded plugin: '%s'\n", module.name());

        return register_media_provider (this.generate_id (),
                                        this.root_id,
                                        this.context);
    }

    private string generate_id () {
        string id = Random.next_int ().to_string ();

        // See if generated ID is already in use
        if (this.providers.lookup (id) != null) {
            return generate_id ();
        } else {
            return id;
        }
    }

    private static bool is_dir (File file) {
        weak FileInfo file_info;

        try {
            file_info = file.query_info (FILE_ATTRIBUTE_STANDARD_TYPE,
                                         FileQueryInfoFlags.NONE,
                                         null);
        } catch (Error error) {
            critical ("Failed to query content type for '%s'\n",
                      file.get_path ());

            return false;
        }

        return file_info.get_file_type () == FileType.DIRECTORY;
    }
}

