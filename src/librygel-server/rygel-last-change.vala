/*
 * Copyright (C) 2012 Openismus GmbH
 *
 * Author: Krzesimir Nowak <krnowak@openismus.com>
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

// Helper class for building ContentDirectory LastChange messages
internal class Rygel.LastChange : Object {
    private const string HEADER =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
        "<StateEvent " +
         "xmlns=\"urn:schemas-upnp-org:av:cds-event\" " +
         "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" " +
         "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
         "xsi:schemaLocation=\"" +
            "urn:schemas-upnp-org:av:cds-event " +
            "http://www.upnp.org/schemas/av/cds-events.xsd\">";

    private const string FOOTER = "</StateEvent>";

    private LinkedList<LastChangeEntry> entries;
    private StringBuilder str;
    private bool update;
    private bool clear_on_add;

    public LastChange () {
        this.entries = new LinkedList<LastChangeEntry> ();
        this.str = new StringBuilder ();
        this.update = true;
        this.clear_on_add = false;
    }

    public void add_event (LastChangeEntry entry) {
        if (this.clear_on_add) {
            this.clear_on_add = false;
            this.entries.clear ();
        }
        this.entries.add (entry);
        this.update = true;
    }

    public void clear_on_new_event () {
        this.clear_on_add = true;
    }

    public string get_log () {
        if (this.update) {
            this.str.erase ();

            this.str.append (HEADER);
            foreach (LastChangeEntry entry in this.entries) {
                str.append (entry.to_string ());
            }
            this.str.append (FOOTER);
            this.update = false;
        }

        return this.str.str;
    }
}
