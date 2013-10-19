/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Andreas Henriksson <andreas@fatal.se>
 *
 * Authors: Andreas Henriksson <andreas@fatal.se>
 *          Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using GUPnP;

/**
 * Represents a subtitle for a video.
 */
public class Rygel.Subtitle {
    public string uri;
    public string mime_type;
    public string caption_type;

    public int64 size = -1;   // Size in bytes

    public Subtitle (string mime_type = "text/plain",
                     string caption_type = "srt") {
        this.mime_type = mime_type;
        this.caption_type = caption_type;
    }

    internal void add_didl_node (DIDLLiteItem didl_item) {
        Xml.Node *item_node = didl_item.xml_node;
        Xml.Node *root_node = item_node->doc->get_root_element ();

        weak Xml.Ns sec_ns = root_node->new_ns ("http://www.sec.co.kr/", "sec");
        // sec_ns apparently already existed. Search for the namespace node
        if (sec_ns == null) {
            weak Xml.Ns it = root_node->ns_def;
            while (it != null) {
                if (it.prefix == "sec") {
                    sec_ns = it;

                    break;
                }
                it = it.next;
            }
        }

        Xml.Node *sec_node = item_node->new_child (sec_ns,
                                                   "CaptionInfoEx",
                                                   this.uri);

        sec_node->new_ns_prop (sec_ns, "type", this.caption_type);
    }
}
