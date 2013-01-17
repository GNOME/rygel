/* Copyright (C) 2012 Intel Corporation
 *
 * Permission to use, copy, modify, distribute, and sell this example
 * for any purpose is hereby granted without fee.
 * It is provided "as is" without express or implied warranty.
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
    GError *error = NULL;
    GMainLoop *loop;

    g_type_init ();
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
