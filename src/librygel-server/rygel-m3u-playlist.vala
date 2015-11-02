/*
 * Copyright (C) 2013 Jens Georg.
 *
 * Authors: Jens Georg <mail@jensge.org>
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

/**
 * Serializer class that serializes to an EXTM3U playlist for use with normal
 * media players or UPnP Renderers that don't support DIDL_S.
 *
 * For the description of the EXTM3U format, see
 * http://en.wikipedia.org/wiki/M3U#Extended_M3U_directives
 */
internal class Rygel.M3UPlayList : Object {
    private LinkedList<DIDLLiteItem> items;

    // We need this writer for the namespaces, the document etc.
    private DIDLLiteWriter writer;

    public M3UPlayList () {
        Object ();
    }

    public override void constructed () {
        this.items = new LinkedList<DIDLLiteItem> ();
        this.writer = new DIDLLiteWriter (null);
    }


    public DIDLLiteItem? add_item () {
        this.items.add (this.writer.add_item ());

        return this.items.last ();
    }

    public string get_string () {
        var builder = new StringBuilder ("#EXTM3U\r\n");

        foreach (var item in this.items) {
            var resources = item.get_resources ();
            if (resources != null) {
                var authors = item.get_artists ();
                builder.append_printf ("#EXTINF:%ld,",
                                       resources.data.duration);
                if (authors != null) {
                    builder.append_printf ("%s - ",
                                           authors.data.get_name () ??
                                               _("Unknown"));
                }

                builder.append (item.title ?? _("Unknown"));
                builder.append ("\r\n");
                builder.append (resources.data.uri);
                builder.append ("\r\n");
            }
        }

        return builder.str;
    }
}
