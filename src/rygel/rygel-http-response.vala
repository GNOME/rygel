/*
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

public class Rygel.HTTPResponse : GLib.Object {
    public Soup.Server server { get; private set; }
    protected Soup.Message msg;

    public signal void eos ();

    public HTTPResponse (Soup.Server  server,
                         Soup.Message msg,
                         bool         partial) {
        this.server = server;
        this.msg = msg;

        server.pause_message (this.msg);

        if (partial) {
            this.msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            this.msg.set_status (Soup.KnownStatusCode.OK);
        }

        this.server.request_aborted += on_request_aborted;
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.Message       msg,
                                     Soup.ClientContext client) {
        // Ignore if message isn't ours
        if (msg == this.msg)
            this.end (true);
    }

    public void set_mime_type (string mime_type) {
        this.msg.response_headers.append ("Content-Type", mime_type);
    }

    public void push_data (void *data, size_t length) {
        this.msg.response_body.append (Soup.MemoryUse.COPY,
                                       data,
                                       length);

        this.server.unpause_message (this.msg);
    }

    public virtual void end (bool aborted) {
        this.eos ();
    }
}

