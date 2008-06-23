/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using GLib;
using GUPnP;

public class GUPnP.MediaReceiverRegistrar: Service {

    construct {
        this.action_invoked["IsAuthorized"] += this.is_authorized_cb;
        this.action_invoked["IsValidated"] += this.is_authorized_cb;
        this.action_invoked["RegisterDevice"] += this.register_device_cb;
    }

    /* IsAuthorized and IsValided action implementations (fake) */
    private void is_authorized_cb (MediaReceiverRegistrar registrar,
                                   ServiceAction          action) {
        action.set ("Result", typeof (int), 1);

        action.return ();
    }

    private void register_device_cb (MediaReceiverRegistrar registrar,
                                     ServiceAction          action) {
        action.set ("RegistrationRespMsg",
                    typeof (string),
                    "WhatisSupposedToBeHere");

        action.return ();
    }
}

