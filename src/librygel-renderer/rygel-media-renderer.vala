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

    public Plugin (Rygel.MediaPlayer root_container) {
        base ("LibRygelRenderer", _("LibRygelRenderer"));
    }

    public override Rygel.MediaPlayer? get_player () {
        return this.player;
    }
}

/**
 * This class may be used to implement in-process UPnP-AV media renderers.
 *
 * Call rygel_media_device_add_interface() on the RygelMediaServer to allow it
 * to serve media via that network interface.
 *
 * See the standalone-renderer.c example.
 */
public class Rygel.MediaRenderer : MediaDevice {

    /**
     * Create a MediaRenderer to serve the media in the RygelMediaContainer.
     * For instance, you might use a RygelSimpleContainer. Alternatively,
     * you might use your own RygelMediaContainer implementation.
     *
     * Assuming that the RygelMediaContainer is correctly implemented,
     * the RygelMediaServer will respond appropriately to changes in the
     * RygelMediaContainer.
     */
    public MediaRenderer (string title, MediaPlayer player) {
        base ();
        this.plugin = new global::Plugin (player);
        this.plugin.title = title;
    }
}
