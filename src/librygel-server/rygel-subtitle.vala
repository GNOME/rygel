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

using GUPnP;

/**
 * Represents a subtitle for a video.
 */
public class Rygel.Subtitle {
    public string uri;
    public string mime_type;
    public string caption_type;
    public string file_extension;

    public int64 size = -1;   // Size in bytes

    public Subtitle (string mime_type = "text/srt",
                     string caption_type = "srt",
                     string file_extension = "srt") {
        this.mime_type = mime_type;
        this.caption_type = caption_type;
        this.file_extension = file_extension;
    }

    internal void add_didl_node (DIDLLiteItem didl_item) {
        Xml.Node *item_node = didl_item.xml_node;
        Xml.Node *root_node = item_node->doc->get_root_element ();

        var sec_ns = XMLUtils.get_namespace (root_node, "http://www.sec.co.kr/", "sec");

        Xml.Node *sec_node = item_node->new_child (sec_ns,
                                                   "CaptionInfoEx",
                                                   this.uri);

        sec_node->new_ns_prop (sec_ns, "type", this.caption_type);
    }

    internal virtual MediaResource get_resource (string protocol, int index) {
        var name = "%s_subtitle_%2d".printf (protocol, index);

        var res = new MediaResource (name);

        res.size = this.size;
        res.mime_type = this.mime_type;
        res.protocol = protocol;

        // Note: These represent best-case. The MediaServer/HTTPServer can
        // dial these back
        res.dlna_flags |= DLNAFlags.INTERACTIVE_TRANSFER_MODE |
                          DLNAFlags.BACKGROUND_TRANSFER_MODE |
                          DLNAFlags.CONNECTION_STALL |
                          DLNAFlags.DLNA_V15;
        res.dlna_operation = DLNAOperation.RANGE;
        res.dlna_conversion = DLNAConversion.TRANSCODED;
        res.extension = this.file_extension;

        res.uri = this.uri;

        return res;
    }
}
