/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This file is part of Rygel.
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

/**
 * Basic implementation of MS MediaReceiverRegistrar service version 1.
 */
internal class Rygel.MediaReceiverRegistrar: Service {
    public const string UPNP_ID =
                    "urn:microsoft-com:serviceId:X_MS_MediaReceiverRegistrar";
    // UPnP requires that points replaced by hyphens in domain names
    public const string UPNP_TYPE =
                    "urn:microsoft-com:service:X_MS_MediaReceiverRegistrar:1";
    // The XBox however doesn't like that so we replace it in the service
    // description later
    public const string COMPAT_TYPE =
                    "urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1";
    public const string DESCRIPTION_PATH =
                    "xml/X_MS_MediaReceiverRegistrar1.xml";

    public override void constructed () {
        base.constructed ();

        this.action_invoked["IsAuthorized"].connect (this.is_authorized_cb);
        this.action_invoked["IsValidated"].connect (this.is_authorized_cb);

        this.query_variable["AuthorizationGrantedUpdateID"].connect
                                        (this.query_state);
        this.query_variable["AuthorizationDeniedUpdateID"].connect
                                        (this.query_state);
        this.query_variable["ValidationSucceededUpdateID"].connect
                                        (this.query_state);
        this.query_variable["ValidationRevokedUpdateID"].connect
                                        (this.query_state);
    }

    /* IsAuthorized and IsValided action implementations (fake) */
    private void is_authorized_cb (Service       registrar,
                                   ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("Result", typeof (int), 1);

        action.return_success ();
    }

    private void query_state (Service        registrar,
                              string         variable,
                              ref GLib.Value value) {
        value.init (typeof (int));
        value.set_int (0);
    }
}
