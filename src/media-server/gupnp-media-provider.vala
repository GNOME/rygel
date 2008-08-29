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

public errordomain GUPnP.MediaProviderError {
    NO_SUCH_OBJECT
}

public abstract class GUPnP.MediaProvider : GLib.Object {
    /* Properties */
    public string# root_id { get; construct; }
    public string# root_parent_id { get; construct; }
    public string# title { get; private construct; }
    public GUPnP.Context context { get; construct; }

    public abstract string browse (string   container_id,
                                    string   filter,
                                    uint     starting_index,
                                    uint     requested_count,
                                    string   sort_criteria,
                                    out uint number_returned,
                                    out uint total_matches,
                                    out uint update_id) throws Error;

    public abstract string get_metadata (string  object_id,
                                         string  filter,
                                         string  sort_criteria,
                                         out uint update_id) throws Error;

    public abstract uint get_root_children_count ();
}

