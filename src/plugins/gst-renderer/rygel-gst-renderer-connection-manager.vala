/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

public class Rygel.GstRenderer.ConnectionManager : Rygel.ConnectionManager {
    private string[] protocols = { "http-get", "rtsp" };
    private string[] mime_types = { "audio/mpeg",
                                    "application/ogg",
                                    "audio/x-vorbis",
                                    "audio/x-vorbis+ogg",
                                    "audio/x-ms-wma",
                                    "audio/x-ms-asf",
                                    "audio/x-flac",
                                    "audio/x-mod",
                                    "audio/x-wav",
                                    "audio/x-ac3",
                                    "audio/x-m4a",
                                    "video/x-theora",
                                    "video/x-dirac",
                                    "video/x-wmv",
                                    "video/x-wma",
                                    "video/x-msvideo",
                                    "video/x-3ivx",
                                    "video/x-3ivx",
                                    "video/x-matroska",
                                    "video/mpeg",
                                    "video/mp4",
                                    "video/x-ms-asf",
                                    "video/x-xvid",
                                    "video/x-ms-wmv",
                                    "audio/L16;rate=44100;channels=2",
                                    "audio/L16;rate=44100;channels=1" };

    public override void constructed () {
        base.constructed ();

        this.connection_ids       = "0";
        this.source_protocol_info = "";
        this.sink_protocol_info = "";

        foreach (var protocol in this.protocols) {
            foreach (var mime_type in this.mime_types) {
                if (this.mime_types[0] != mime_type) {
                    this.sink_protocol_info += ",";
                }

                this.sink_protocol_info += protocol + ":*:" + mime_type + ":*";
            }
        }
    }
}
