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
using Gee;

// Helper class for building LastChange messages
public class Rygel.GstChangeLog : Object {
    public unowned Service service { get; set; }

    private string service_ns;

    private StringBuilder str;

    private HashMap<string, string> hash;

    private uint timeout_id = 0;

    public GstChangeLog (Service? service, string service_ns) {
        this.service = service;
        this.service_ns = service_ns;
        this.str = new StringBuilder ();
        this.hash = new HashMap<string, string> ();
    }

    ~GstChangeLog () {
        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
        }
    }

    private bool timeout () {
        // Emit notification
        this.service.notify ("LastChange", typeof (string), finish ());
        debug ("LastChange sent");

        // Reset
        this.hash.clear ();
        this.str.erase (0, -1);
        this.timeout_id = 0;

        return false;
    }

    private void ensure_timeout () {
        // Make sure we have a notification timeout
        if (this.service != null && this.timeout_id == 0) {
            debug ("Setting up timeout for LastChange");
            this.timeout_id = Timeout.add (200, timeout);
        }
    }

    public void log (string variable, string value) {
        debug (@"'%s = %s' logged", variable, value);
        this.hash.set (variable, "<%s val=\"%s\"/>".printf (variable, value));

        ensure_timeout ();
    }

    public void log_with_channel (string variable,
                                  string value,
                                  string channel) {
        this.hash.set (variable,
                       "<%s val=\"%s\" channel=\"%s\"/>".printf (variable,
                                                                 value,
                                                                 channel));

        ensure_timeout ();
    }

    public string finish () {
        this.str.append ("<Event xmlns=\"" +
                         this.service_ns +
                         "\"><InstanceID val=\"0\">");
        foreach (string line in this.hash.values) {
            this.str.append (line);
        }
        this.str.append ("</InstanceID></Event>");

        return this.str.str;
    }
}
