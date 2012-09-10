/*
 * Copyright (C) 2012 Openismus GmbH.
 * Copyright (C) 2012 Intel Corporation.
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

internal class Rygel.Playbin.WrappingPlugin : Rygel.MediaRendererPlugin {
    private MediaPlayer player;

    public WrappingPlugin (Gst.Element playbin) {
        base ("LibRygel-Renderer", _("LibRygel Renderer"));
        this.player = new Player.wrap (playbin);
    }


    public override MediaPlayer? get_player () {
        return this.player;
    }
}

/**
 * A UPnP renderer that uses a GStreamer Playbin2 element.
 *
 * Using Gst.Playbin2 as a model, it reflects any changes done externally, such as
 * changing the currently played URI, volume, pause/play etc., to UPnP.
 *
 * Likewise, the playbin can be modified externally using UPnP.
 */
public class Rygel.Playbin.Renderer : Rygel.MediaDevice {
    /**
     * Create a new instance of Renderer.
     *
     * Renderer will instantiate its own instance of Gst.Playbin2.
     * The Gst.Playbin2 can be accessed by using Player.get_default().playbin
     *
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public Renderer (string title) {
        base ();
        this.plugin = new Plugin ();
        this.prepare_upnp (title);
    }

    /**
     * Create a new instance of Renderer, wrapping an existing Playbin2
     * instance.
     *
     * @param pipeline Instance of Gst.PlayBin2 to wrap.
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public Renderer.wrap (Gst.Element pipeline, string title) {
        base ();
        this.plugin = new WrappingPlugin (pipeline);
        this.prepare_upnp (title);
    }

    private void prepare_upnp (string title) {
        this.plugin.title = title;

        // Always listen on localhost
        this.add_interface ("lo");
    }
}
