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

internal class Rygel.LastChangeObjDel : Rygel.LastChangeEntry {
    private bool sub_tree_update;

    public LastChangeObjDel (string id,
                             uint update_id,
                             bool sub_tree_update) {
        base ("objDel", id, update_id);
        this.sub_tree_update = sub_tree_update;
    }

    protected override string additional_info () {
        var str = new StringBuilder ();
        var st_update = (this.sub_tree_update ? "1" : "0");

        str.append ("stUpdate=\"" + st_update + "\"");

        return str.str;
    }
}
