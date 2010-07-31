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
                                    "http-get:*:video/mp4:*," +
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
