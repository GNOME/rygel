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

        return_val_if_fail (playbin != null, null);
        return_val_if_fail (playbin.get_type ().name() == "GstPlayBin2", null);

        this.player = new Player.wrap (playbin);
    }


    public override MediaPlayer? get_player () {
        return this.player;
    }
}

/**
 * A UPnP renderer that uses a GStreamer Playbin2 element.
 *
 * Using GstPlayBin2 as a model, it reflects any changes done externally, such as
 * changing the currently played URI, volume, pause/play etc., to UPnP.
 *
 * Likewise, the playbin can be modified externally using UPnP.
 *
 * You can retrieve the GstPlayBin2 by calling rygel_playbin_renderer_get_playbin().
 * You should then set the "video-sink" and "audio-sink" properties of the
 * playbin.
 *
 * Call rygel_media_device_add_interface() on the Renderer to allow it
 * to be controlled by a control point and to retrieve data streams via that
 * network interface.
 *
 * See the <link linkend="example">example</link>.
 */
public class Rygel.Playbin.Renderer : Rygel.MediaDevice {
    /**
     * Create a new instance of Renderer.
     *
     * Renderer will instantiate its own instance of GstPlayBin2.
     * The GstPlayBin2 can be accessed by using rygel_playbin_player_get_playbin().
     *
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public Renderer (string title) {
        base ();
        this.plugin = new Plugin ();
        this.prepare_upnp (title);
    }

    /**
     * Create a new instance of Renderer, wrapping an existing GstPlayBin2
     * instance.
     *
     * @param pipeline Instance of GstPlayBin2 to wrap.
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public Renderer.wrap (Gst.Element pipeline, string title) {
        base ();

        return_val_if_fail (pipeline != null, null);
        return_val_if_fail (pipeline.get_type ().name() == "GstPlayBin2", null);

        this.plugin = new WrappingPlugin (pipeline);
        this.prepare_upnp (title);
    }

    /**
     * Get the GstPlaybin2 used by this Renderer.
     */
    public Gst.Element? get_playbin () {
        var player = Rygel.Playbin.Player.get_default ();
        return_val_if_fail (player != null, null);

        return player.playbin;
    }

    private void prepare_upnp (string title) {
        this.plugin.title = title;

        // Always listen on localhost
        this.add_interface ("lo");
    }
}
