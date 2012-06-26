/*
 * Copyright (C) 2012 Openismus GmbH.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using Gee;
using GUPnP;

internal class Rygel.Playbin.RendererContext {
    public RootDevice device;
    public RootDeviceFactory factory;
    public Context context;

    public RendererContext (Context context, Plugin plugin) throws Error {
        this.context = context;
        this.factory = new RootDeviceFactory (context);
        this.device = this.factory.create (plugin);
        this.device.available = true;
    }
}

public class Rygel.Playbin.Renderer : Object {
    private ArrayList<string> interfaces;
    private HashMap<string, Context> contexts;
    private HashMap<string, RendererContext> renderer;
    private ContextManager manager;
    private Plugin plugin;

    public Renderer (string title) {
        manager = ContextManager.create (0);
        manager.context_available.connect (this.on_context_available);
        manager.context_unavailable.connect (this.on_context_unavailable);
        this.interfaces = new ArrayList<string> ();
        this.contexts = new HashMap<string, Context> ();
        this.renderer = new HashMap<string, RendererContext> ();
        plugin = new Plugin ();
        plugin.title = title;

        // Always listen on localhost
        this.add_interface ("lo");
    }

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

    public void remove_interface (string iface) {
        if (!(iface in this.interfaces)) {
            return;
        }

        this.interfaces.remove (iface);

        if (iface in this.contexts.keys) {
            // Sleeping context; remove the context and we're done.
            this.contexts.unset (iface);
        } else if (iface in this.renderer.keys) {
            this.renderer.unset (iface);
        }
    }

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
                var ctx = new RendererContext (context, this.plugin);
                this.renderer[context.interface] = ctx;
            } catch (Error error) {
                warning ("Failed to create renderer context: %s",
                         error.message);
            }
        } else {
            this.contexts[context.interface] = context;
        }
    }

    private void on_context_unavailable (Context context) {
        this.remove_interface (context.interface);
    }
}
