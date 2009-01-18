/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel;
using GUPnP;

public class Rygel.InteractiveResponse : Rygel.HTTPResponse {
    private Seek seek;

    public InteractiveResponse (Soup.Server  server,
                                Soup.Message msg,
                                string       uri,
                                Seek?        seek) throws Error {
        base (server, msg, false);

        this.seek = seek;

        if (seek != null) {
            msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            msg.set_status (Soup.KnownStatusCode.OK);
        }

        File file = File.new_for_uri (uri);

        file.load_contents_async (null, this.on_contents_loaded);
    }

    private void on_contents_loaded (GLib.Object source_object,
                                     GLib.AsyncResult result) {
        File file = (File) source_object;
        string contents;
        size_t file_length;

        try {
           file.load_contents_finish (result,
                                      out contents,
                                      out file_length,
                                      null);
        } catch (Error error) {
            warning ("Failed to load contents from URI: %s: %s\n",
                     file.get_uri (),
                     error.message);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        size_t offset;
        size_t length;
        if (seek != null) {
            offset = (size_t) seek.start;
            length = (size_t) seek.length;

            assert (offset < file_length);
            assert (length <= file_length);
        } else {
            offset = 0;
            length = file_length;
        }

        char *data = (char *) contents + offset;

        this.push_data (data, length);
        this.end (false);
    }
}

