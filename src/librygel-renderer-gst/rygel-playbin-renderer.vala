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

/**
 * An in-process UPnP renderer that uses a GStreamer Playbin element.
 *
 * Using GstPlayBin as a model, it reflects any changes done externally, such as
 * changing the currently played URI, volume, pause/play etc., to UPnP.
 *
 * Likewise, the playbin can be modified externally using UPnP.
 *
 * You can retrieve the GstPlayBin by calling rygel_playbin_renderer_get_playbin().
 * You should then set the "video-sink" and "audio-sink" properties of the
 * playbin.
 *
 * Call rygel_media_device_add_interface() on the Renderer to allow it
 * to be controlled by a control point and to retrieve data streams via that
 * network interface.
 *
 * See the <link linkend="implementing-renderers-gst">Implementing GStreamer-based Renderers</link> section.
 */
public class Rygel.Playbin.Renderer : Rygel.MediaRenderer {
    /**
     * Create a new instance of Renderer.
     *
     * Renderer will instantiate its own instance of GstPlayBin.
     * The GstPlayBin can be accessed by using rygel_playbin_player_get_playbin().
     *
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public Renderer (string title) {
        Object (title: title,
                player: Player.get_default ());
    }

    /**
     * Create a new instance of Renderer, wrapping an existing GstPlayBin
     * instance.
     *
     * @param pipeline Instance of GstPlayBin to wrap.
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public Renderer.wrap (Gst.Element pipeline, string title) {
        return_val_if_fail (pipeline != null, null);
        return_val_if_fail (pipeline.get_type ().name() == "GstPlayBin", null);

        Object (title: title,
                player: new Player.wrap (pipeline));
    }

    /**
     * Get the GstPlayBin used by this Renderer.
     */
    public Gst.Element? get_playbin () {
        var player = Rygel.Playbin.Player.get_default ();
        return_val_if_fail (player != null, null);

        return player.playbin;
    }
}
