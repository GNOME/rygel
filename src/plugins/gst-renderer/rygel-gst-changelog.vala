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

// Helper class for building LastChange messages
public class Rygel.GstChangeLog : Object {
    public unowned Service service { get; set; }

    private StringBuilder str;

    private Gee.HashMap<string, string> hash;

    private uint timeout_id = 0;

    public GstChangeLog (Service? service) {
        service = service;
        str = new StringBuilder ();
        hash = new Gee.HashMap<string, string> (str_hash, str_equal, str_equal);
    }

    ~GstChangeLog () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }
    }

    private bool timeout () {
        // Emit notification
        service.notify ("LastChange", typeof (string), finish ());

        // Reset
        hash.clear ();
        str.erase (0, -1);
        timeout_id = 0;

        return false;
    }

    private void ensure_timeout () {
        // Make sure we have a notification timeout
        if (service != null && timeout_id == 0) {
            timeout_id = Timeout.add (200, timeout);
        }
    }

    public void log (string var, string val) {
        hash.set (var, "<%s val=\"%s\"/>".printf (var, val));

        ensure_timeout ();
    }

    public void log_with_channel (string var, string val, string channel) {
        hash.set (var, "<%s val=\"%s\" channel=\"%s\"/>".printf (var, val,
                                                                 channel));

        ensure_timeout ();
    }

    public string finish () {
        str.append ("<Event xmlns=\"" +
                    "urn:schemas-upnp-org:metadata-1-0/AVT_RCS\">" +
                    "<InstanceID val=\"0\">");
        foreach (string line in hash.values) {
            str.append (line);
        }
        str.append ("</InstanceID></Event>");

        return str.str;
    }
}
