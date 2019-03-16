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
internal abstract class Rygel.LastChangeEntry : Object {
    private string tag;
    private string id;
    private uint update_id;

    protected LastChangeEntry (string tag, string id, uint update_id) {
        this.tag = tag;
        this.id = id;
        this.update_id = update_id;
    }

    protected abstract string additional_info ();

    public string to_string () {
        var str = new StringBuilder ();
        var info = this.additional_info ();

        str.append ("<" + this.tag + " " +
                    "objID=\"" + this.id + "\" " +
                    "updateID=\"" + this.update_id.to_string () + "\"");

        if (info.length > 0) {
            str.append (" " + info);
        }
        str.append ("/>");

        return str.str;
    }
}
