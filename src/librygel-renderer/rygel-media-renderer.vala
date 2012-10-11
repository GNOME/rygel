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

internal class Plugin : Rygel.MediaRendererPlugin {
    private Rygel.MediaPlayer player;

    public Plugin (Rygel.MediaPlayer root_container,
                   Rygel.PluginCapabilities capabilities) {
        base ("LibRygelRenderer", _("LibRygelRenderer"), null, capabilities);
    }

    public override Rygel.MediaPlayer? get_player () {
        return this.player;
    }
}

/**
 * This class may be used to implement in-process UPnP-AV media renderers.
 *
 * Call rygel_media_device_add_interface() on the RygelMediaRenderer to allow it
 * to render media from that network interface.
 *
 * See the standalone-renderer.c example.
 */
public class Rygel.MediaRenderer : MediaDevice {

    /**
     * Create a RygelMediaRenderer to render content via a RygelMediaPlayer.
     */
    public MediaRenderer (string title,
                          MediaPlayer player,
                          PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        base ();
        this.plugin = new global::Plugin (player, capabilities);
        this.plugin.title = title;
    }
}
