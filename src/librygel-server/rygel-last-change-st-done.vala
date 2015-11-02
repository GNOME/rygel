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

internal class Rygel.LastChangeStDone : Rygel.LastChangeEntry {
    public LastChangeStDone (string id,
                             uint update_id) {
        base ("stDone", id, update_id);
    }

    protected override string additional_info () {
        return "";
    }
}
