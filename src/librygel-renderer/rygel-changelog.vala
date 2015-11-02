/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Gee;

// Helper class for building LastChange messages
internal class Rygel.ChangeLog : Object {
    private WeakRef service;

    private string service_ns;

    private StringBuilder str;

    private HashMap<string, string> hash;

    private uint timeout_id = 0;

    public ChangeLog (Service? service, string service_ns) {
        this.service = WeakRef (service);
        this.service_ns = service_ns;
        this.str = new StringBuilder ();
        this.hash = new HashMap<string, string> ();
    }

    ~ChangeLog () {
        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
        }
    }

    private bool timeout () {
        // Check whether the AVTransport service has not been destroyed already
        var service = this.service.get () as Service;
        if (service == null)
            return false;

        // Emit notification
        service.notify ("LastChange", typeof (string), this.finish ());
        debug ("LastChange sent");

        // Reset
        this.hash.clear ();
        this.str.erase (0, -1);
        this.timeout_id = 0;

        return false;
    }

    private void ensure_timeout () {
        // Make sure we have a notification timeout
        if (this.service.get() != null && this.timeout_id == 0) {
            debug ("Setting up timeout for LastChange");
            this.timeout_id = Timeout.add (150, this.timeout);
        }
    }

    public void log (string variable, string value) {
        debug (@"'%s = %s' logged", variable, value);
        this.hash.set (variable,
                       "<%s val=\"%s\"/>".printf (variable,
                                                  Markup.escape_text (value)));

        this.ensure_timeout ();
    }

    public void log_with_channel (string variable,
                                  string value,
                                  string channel) {
        var text = "<%s val=\"%s\" channel=\"%s\"/>".printf
                                        (variable,
                                         Markup.escape_text(value),
                                         Markup.escape_text(channel));
        this.hash.set (variable, text);

        this.ensure_timeout ();
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
