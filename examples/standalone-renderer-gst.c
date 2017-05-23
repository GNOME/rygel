/*
 * Copyright (C) 2012 Openismus GmbH.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/*
 * Demo application for librygel-renderer-gst.
 *
 * Creates a simple stand-alone UPnP renderer that renders any visual content
 * in ASCII-art using GStreamer's cacasink element.
 *
 * Usage:
 *   standalone-renderer [<network device>]
 *
 * If no network device is given on the commandline, the program falls back to
 * eth0.
 *
 * To do anything useful, another UPnP server + UPnP controller is necessary
 * to tell it which media file to show.
 */

#include "rygel-renderer-gst.h"
#include "rygel-core.h"

int main(int argc, char *argv[])
{
    GstElement *playbin, *sink, *asink;
    RygelPlaybinRenderer *renderer;
    GMainLoop *loop;

    gst_init (&argc, &argv);

    g_set_application_name ("Standalone-Renderer");

    renderer = rygel_playbin_renderer_new ("LibRygel renderer demo");
    playbin = rygel_playbin_renderer_get_playbin (renderer);
    sink = gst_element_factory_make ("cacasink", NULL);
    g_object_set (G_OBJECT (sink),
                  "dither", 53,
                  "anti-aliasing", TRUE,
                  NULL);

    asink = gst_element_factory_make ("pulsesink", NULL);

    g_object_set (G_OBJECT (playbin),
                  "video-sink", sink,
                  "audio-sink", asink,
                  NULL);

    if (argc >= 2) {
        rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (renderer), argv[1]);
    } else {
        rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (renderer), "eth0");
    }

    loop = g_main_loop_new (NULL, FALSE);
    g_main_loop_run (loop);

    return 0;
}
