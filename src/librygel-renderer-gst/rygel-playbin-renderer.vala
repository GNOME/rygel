/*
 * Copyright (C) 2012 Openismus GmbH.
 * Copyright (C) 2012 Intel Corporation.
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
public class Rygel.PlaybinRenderer : Rygel.MediaRenderer {
    /**
     * Create a new instance of Renderer.
     *
     * Renderer will instantiate its own instance of GstPlayBin.
     * The GstPlayBin can be accessed by using rygel_playbin_player_get_playbin().
     *
     * @param title Friendly name of the new UPnP renderer on the network.
     */
    public PlaybinRenderer (string title) {
        try {
            Object (title: title,
                    player: PlaybinPlayer.instance ());
        } catch (Error error) {
            warning (error.message);

            return_val_if_fail (false, null);
        }
    }

    /**
     * Get the GstPlayBin used by this Renderer.
     */
    public Gst.Element? get_playbin () {
        try {
            var player = Rygel.PlaybinPlayer.instance ();

            return player.playbin;
        } catch (Error error) {
            warning (error.message);

            return null;
        }
    }
}
