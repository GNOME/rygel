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

public class GUPnP.MediaManager : GLib.Object, MediaProvider {
    private DIDLLiteWriter didl_writer;

    /* Properties */
    public string# root_id { get; construct; }
    public string# root_parent_id { get; construct; }
    public GUPnP.Context context { get; construct; }
    public uint32 system_update_id { get; private set; }

    /* HashTable of Media Providers
     * keys -> root-id assigned to Media Provider
     * values -> Media Provider objects
     */
    HashTable<string, MediaProvider> providers;

    construct {
        this.providers = new HashTable<string, MediaProvider>
                                ((HashFunc) id_hash_func,
                                 (EqualFunc) is_root_equal);

        MediaTracker tracker = new MediaTracker ("1",
                                                 this.root_id,
                                                 this.context);
        providers.insert ("1", tracker);

        this.didl_writer = new DIDLLiteWriter ();

        this.system_update_id = 0;
    }

    /* Pubic methods */
    public MediaManager (GUPnP.Context context) {
        this.root_id = "0";
        this.root_parent_id = "-1";
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

        string id = this.remove_root_id_prefix (container_id);

        if (id == this.root_id) {
            didl = this.browse_root_container (out number_returned,
                                               out total_matches,
                                               out update_id);
        } else {
            weak MediaProvider provider = this.providers.lookup (id);
            if (provider != null) {
                didl = provider.browse (id,
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

        string id = this.remove_root_id_prefix (object_id);

        if (id == this.root_id) {
            didl = this.get_root_container_metadata (out update_id);
        } else {
            weak MediaProvider provider = this.providers.lookup (id);
            if (provider != null) {
                didl = provider.get_metadata (id,
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

    /* Private methods */
    private string browse_root_container (out uint number_returned,
                                          out uint total_matches,
                                          out uint update_id) {
        /* Start DIDL-Lite fragment */
        this.didl_writer.start_didl_lite (null, null, true);

        this.providers.for_each ((key, value) => {
            add_container ((string) key,
                           this.root_id,
                           (string) key,  /* FIXME */
                           -1);           /* FIXME */
            });

        number_returned = total_matches = this.providers.size ();

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
                       this.root_id, /* FIXME */
                       this.providers.size ());

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
        string exported_id, exported_parent_id;

        if (id == this.root_id)
            exported_id = id;
        else
            exported_id = this.root_id + ":" + id;

        if (parent_id == this.root_id)
            exported_parent_id = parent_id;
        else
            exported_parent_id = this.root_id + ":" + parent_id;

        this.didl_writer.start_container (this.root_id + ":" + id,
                                          exported_parent_id,
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

    string remove_root_id_prefix (string id) {
        string[] tokens;

        tokens = id.split (":", 2);

        if (tokens[1] != null)
            return tokens[1];
        else
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
}

