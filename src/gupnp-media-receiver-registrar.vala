using GLib;
using GUPnP;

public class GUPnP.MediaReceiverRegistrar: Service {

    construct {
        /* FIXME: Use Vala's syntax for connecting signals when Vala adds
        * support for signal details. */
        Signal.connect (this,
                        "action-invoked::IsAuthorized",
                        (GLib.Callback) this.is_authorized_cb,
                        null);
        Signal.connect (this,
                        "action-invoked::IsValidated",
                        (GLib.Callback) this.is_authorized_cb,
                        null);
        Signal.connect (this,
                        "action-invoked::RegisterDevice",
                        (GLib.Callback) this.register_device_cb,
                        null);
    }

    /* IsAuthorized and IsValided action implementations (fake) */
    private void is_authorized_cb (ServiceAction action) {
        action.set ("Result", typeof (int), 1);

        action.return ();
    }

    private void register_device_cb (ServiceAction action) {
        action.set ("RegistrationRespMsg",
                    typeof (string),
                    "WhatisSupposedToBeHere");

        action.return ();
    }
}

