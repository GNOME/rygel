/*
 * Copyright (C) 2012 Openismus GmbH.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

using Gee;
using GUPnP;

internal class Rygel.DeviceContext {
    public RootDevice device;
    public RootDeviceFactory factory;
    public Context context;

    public DeviceContext (Context context, Rygel.Plugin plugin) throws Error {
        this.context = context;
        this.factory = new RootDeviceFactory (context);
        this.device = this.factory.create (plugin);
        this.device.available = true;
    }
}

/**
 * This is a base class for implementations of UPnP devices,
 * such as RygelMediaServer and RygelMediaRenderer.
 *
 * Use rygel_media_device_add_interface() to allow this
 * device to respond to UPnP messages on a network interface.
 */
public abstract class Rygel.MediaDevice : Object {
    private ArrayList<string> interfaces;
    private HashMap<string, Context> contexts;
    private HashMap<string, DeviceContext> devices;
    private ContextManager manager;

    public Rygel.Plugin plugin { construct set; protected get; }
    public string title { construct; protected get; }
    public PluginCapabilities capabilities {
        construct;
        protected get;
        default = PluginCapabilities.NONE;
    }

    public override void constructed () {
        base.constructed ();

        var port = 0;
        try {
            port = MetaConfig.get_default ().get_port ();
        } catch (Error error) {
            debug ("No listening port specified, using random TCP port");
        }

        this.manager = ContextManager.create (port);
        this.manager.context_available.connect (this.on_context_available);
        this.manager.context_unavailable.connect (this.on_context_unavailable);
        this.interfaces = new ArrayList<string> ();
        this.contexts = new HashMap<string, Context> ();
        this.devices = new HashMap<string, DeviceContext> ();
    }

    /**
     * Add a network interface the device should listen on.
     *
     * If the network interface is not already up, it will be used as soon as
     * it's ready. Otherwise it's used right away.
     *
     * @param iface Name of the network interface, e.g. eth0
     */
    public void add_interface (string iface) {
        if (!(iface in this.interfaces)) {
            this.interfaces.add (iface);

            // Check if we already have a context for this, then enable the
            // device right away
            if (iface in this.contexts.keys) {
                this.on_context_available (this.contexts[iface]);
            }
        }
    }

    /**
     * Remove a previously added network interface from the device.
     *
     * @param iface Name of the network interface, e.g. eth0
     */
    public void remove_interface (string iface) {
        if (!(iface in this.interfaces)) {
            return;
        }

        this.interfaces.remove (iface);

        if (iface in this.devices.keys) {
            this.contexts[iface] = this.devices[iface].context;
            this.devices.unset (iface);
        }
    }

    /**
     * Get a list of the network interfaces the device is currently allowed
     * to use.
     *
     * @return list of interface names.
     */
    public GLib.List<string> get_interfaces () {
        GLib.List<string> result = null;

        foreach (var iface in this.interfaces) {
            result.prepend (iface);
        }

        result.reverse ();

        return result;
    }

    private void on_context_available (Context context) {
        if (context.interface in this.interfaces) {
            try {
                var ctx = new DeviceContext (context, this.plugin);
                this.devices[context.interface] = ctx;
            } catch (Error error) {
                warning ("Failed to create device context: %s",
                         error.message);
            }
        } else {
            this.contexts[context.interface] = context;
        }
    }

    private void on_context_unavailable (Context context) {
        if (context.interface in this.devices.keys) {
            this.devices.unset (context.interface);
        } else {
            this.contexts.unset (context.interface);
        }
    }
}
