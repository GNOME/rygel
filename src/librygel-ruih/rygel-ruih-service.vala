/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 * Contact: http://www.cablelabs.com/
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
using Gee;

/**
 * Basic implementation of UPnP RemoteUIServer service version 1.
 */
internal class Rygel.RuihService: Service {
    public const string UPNP_ID =
                     "urn:upnp-org:serviceId:RemoteUIServer";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:RemoteUIServer:1";
    public const string DESCRIPTION_PATH =
                    "xml/RemoteUIServerService.xml";

    public override void constructed () {
        base.constructed ();

        this.query_variable["UIListingUpdate"].connect
                                        (this.query_ui_listing);

        this.action_invoked["GetCompatibleUIs"].connect
                                        (this.get_compatible_uis_cb);

        var manager = RuihServiceManager.get_default ();
        manager.updated.connect (this.update_plugin_availability);
        this.update_plugin_availability ();
    }

    /* Browse action implementation */
    private void get_compatible_uis_cb (Service       content_dir,
                                        ServiceAction action) {

        string input_device_profile, input_ui_filter;
        action.get ("InputDeviceProfile",
                        typeof (string),
                        out input_device_profile);
        action.get ("UIFilter", typeof (string), out input_ui_filter);

        if (action.get_argument_count () < 2) {
            action.return_error (402, _("Invalid argument"));
            return;
        }

        try {
            var manager = RuihServiceManager.get_default ();
            var compat_ui = manager.get_compatible_uis (input_device_profile,
                                                        input_ui_filter);

            action.set ("UIListing", typeof (string), compat_ui);
            action.return_success ();
        } catch (RuihServiceError e) {
            action.return_error (e.code, e.message);
        }
    }

    private void query_ui_listing (Service        ruih_service,
                                   string         variable,
                                   ref GLib.Value value) {
        value.init (typeof (string));
        value.set_string ("");
    }

    private void update_plugin_availability () {
        var manager = RuihServiceManager.get_default ();
        var plugin = this.root_device.resource_factory as Plugin;


        plugin.active = manager.ui_list_available ();
    }
}
