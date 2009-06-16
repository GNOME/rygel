/*
 * Copyright (C) 2008 OpenedHand Ltd.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
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

using GUPnP;

public class Rygel.GstConnectionManager : Rygel.ConnectionManager {
    // Creates a list of supported sink protocols based on GStreamer's
    // registry. We don't use this because of the spam it generates ..
    /*
    private void setup_sink_protocol_info () {
        Gst.Registry reg = Gst.Registry.get_default ();

        Gee.HashSet<string> mime_types =
            new Gee.HashSet<string> (GLib.str_hash, GLib.str_equal);

        weak List<Gst.ElementFactory> factories =
                reg.get_feature_list (typeof (Gst.ElementFactory));
        foreach (Gst.ElementFactory factory in factories) {
            weak List<Gst.StaticPadTemplate> templates =
                factory.staticpadtemplates;
            foreach (weak Gst.StaticPadTemplate template in templates) {
                if (template.direction != Gst.PadDirection.SINK) {
                    continue;
                }

                Gst.Caps caps = template.static_caps.get ();
                for (int i = 0; i < caps.get_size (); i++) {
                    weak Gst.Structure str =
                        template.static_caps.get_structure (i);

                    mime_types.add (str.get_name ());
                }
            }
        }

        foreach (string type in mime_types) {
            stdout.printf ("%s\n", type);
        }
    }
    */

    public override void constructed () {
        base.constructed ();

        this.connection_ids       = "0";
        this.source_protocol_info = "";
        this.sink_protocol_info   = "http-get:*:audio/mpeg:*," +
                                    "http-get:*:application/ogg:*," +
                                    "http-get:*:audio/x-vorbis:*," +
                                    "http-get:*:audio/x-vorbis+ogg:*," +
                                    "http-get:*:audio/x-ms-wma:*," +
                                    "http-get:*:audio/x-ms-asf:*," +
                                    "http-get:*:audio/x-flac:*," +
                                    "http-get:*:audio/x-mod:*," +
                                    "http-get:*:audio/x-wav:*," +
                                    "http-get:*:audio/x-ac3:*," +
                                    "http-get:*:audio/x-m4a:*," +
                                    "http-get:*:video/x-theora:*," +
                                    "http-get:*:video/x-dirac:*," +
                                    "http-get:*:video/x-wmv:*," +
                                    "http-get:*:video/x-wma:*," +
                                    "http-get:*:video/x-msvideo:*," +
                                    "http-get:*:video/x-3ivx:*," +
                                    "http-get:*:video/x-3ivx:*," +
                                    "http-get:*:video/x-matroska:*," +
                                    "http-get:*:video/mpeg:*," +
                                    "http-get:*:video/x-ms-asf:*," +
                                    "http-get:*:video/x-xvid:*," +
                                    "http-get:*:video/x-ms-wmv:*," +
                                    "http-get:*:audio/L16;" +
                                               "rate=44100;" +
                                               "channels=2:*," +
                                    "http-get:*:audio/L16;" +
                                               "rate=44100;" +
                                               "channels=1:*";
    }
}
