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
 * fullscreen.
 *
 * Usage:
 *   fullscreen-renderer [<network device>]
 *
 * If no network device is given on the commandline, the program falls back to
 * eth0.
 *
 * To do anything useful, another UPnP server + UPnP controller is necessary
 * to tell it which media file to show.
 */

#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>

#include "rygel-core.h"
#include "rygel-renderer-gst.h"

#define LOGO_PATH "/org/gnome/Rygel/FullscreenRenderer/rygel-full.svg"

struct _MainData {
    GtkWindow *window;
    GtkWidget *video;
    GstElement *playbin;
    GdkTexture *texture;
    GdkPaintable *paintable;
    GMainLoop *loop;
};
typedef struct _MainData MainData;

// Toggling the state of the playbin will also change the UPnP state
// of the playback
static void
toggle_play_pause (GstElement *element)
{
    GstStateChangeReturn ret;
    GstState current = GST_STATE_NULL, pending = GST_STATE_NULL;

    ret = gst_element_get_state (element, &current, &pending, GST_SECOND * 5);

    if (ret != GST_STATE_CHANGE_SUCCESS)
        return;

    if (current == GST_STATE_PAUSED) {
        gst_element_set_state (element, GST_STATE_PLAYING);
    }

    if (current == GST_STATE_PLAYING) {
        gst_element_set_state (element, GST_STATE_PAUSED);
    }
}

// Just a couple of convenience keyboard shortcuts
// Space will the usual toggle of play/pause
// Esc and q will quit the renderer
static gboolean
on_key_released (GtkWidget *widget,
                 guint keyval,
                 guint keycode,
                 GdkModifierType state,
                 gpointer user_data)
{
    MainData *data = (MainData *) user_data;

    switch (keyval) {
    case GDK_KEY_space:
        toggle_play_pause (data->playbin);

        return FALSE;
    case GDK_KEY_Escape:
    case GDK_KEY_q:
    case GDK_KEY_Q:
        g_main_loop_quit (data->loop);

        return TRUE;
    default:
        return FALSE;
    }
}

// This message handler will replace the logo with the video paintable
// if the state of the pipeline is "showing video" in some way or another
static gboolean
on_message (GstBus *bus, GstMessage *msg, gpointer user_data)
{
    MainData *data = (MainData *) user_data;

    switch (GST_MESSAGE_TYPE (msg)) {
    case GST_MESSAGE_STATE_CHANGED:
        GstState old_state, new_state, pending_state;
        gst_message_parse_state_changed (msg,
                                         &old_state,
                                         &new_state,
                                         &pending_state);
        if (GST_MESSAGE_SRC (msg) == GST_OBJECT (data->playbin)) {
            if (new_state < GST_STATE_PAUSED) {
                gtk_picture_set_paintable (GTK_PICTURE (data->video),
                                           GDK_PAINTABLE (data->texture));
            } else {
                gtk_picture_set_paintable (GTK_PICTURE (data->video),
                                           data->paintable);
            }
        }
    default:
        break;
    }

    return TRUE;
}

static gboolean
on_close (GtkWindow *self, gpointer user_data)
{
    MainData *data = (MainData *) user_data;

    g_main_loop_quit (data->loop);
    return TRUE;
}

int
main (int argc, char *argv[])
{
    MainData data = { 0 };

    gtk_init ();
    gst_init (&argc, &argv);

    g_set_application_name ("Rygel-Fullscreen-Renderer");

    // Create a new Rygel renderer device (based on GStreamer)
    // We do some steps to setup the contained playbin according to our needs
    // such as ...
    RygelPlaybinRenderer *renderer =
        rygel_playbin_renderer_new ("Rygel Fullscreen renderer demo");
    data.playbin = rygel_playbin_renderer_get_playbin (renderer);

    // ... creating a custom sink for integration with GTK4 ...
    GstElement *sink =
        gst_element_factory_make ("gtk4paintablesink", "gtk4paintablesink");
    if (sink == NULL) {
        g_print ("Could not create gtk4paintablesink. Please check "
                 "your plugin installation.\n");
        return 1;
    }

    // ... hooking it up with the playbin and saving the paintable for later
    g_object_set (data.playbin, "video-sink", sink, NULL);
    g_object_get (sink, "paintable", &(data.paintable), NULL);

    // We check if ww have a GL context on the paintable, if so, we can do
    // Offloading
    g_autoptr (GdkGLContext) context = NULL;
    g_object_get (data.paintable, "gl-context", &context, NULL);
    if (context != NULL) {
        GstElement *bin = gst_element_factory_make ("glsinkbin", "glsinkbin");
        g_assert (bin != NULL);
        g_object_set (bin, "sink", sink, NULL);
        g_object_set (data.playbin, "video-sink", bin, NULL);
    }

    // We also hook up to the pipeline's bus to be able to react to messages
    // On the bus. Note: Internally Rygel configures this to have a signal
    // watch, so you MUST use the message signal here, and not another bus watch
    GstBus *bus = gst_element_get_bus (data.playbin);
    g_signal_connect (G_OBJECT (bus),
                      "message",
                      G_CALLBACK (on_message),
                      &data);

    // Setting up the rest of the UI, which is a basic GtkWindow
    // Containing a GtkPicture. We also disable the cursor on it so it does
    // not get in the way of viewing the video
    data.window = GTK_WINDOW (gtk_window_new ());
    g_signal_connect (data.window,
                      "close-request",
                      G_CALLBACK (on_close),
                      &data);
    data.video = gtk_picture_new ();
    gtk_widget_set_cursor_from_name (data.video, "none");

    // Unconditionally create a GtkGraphicsOffload (it helps us with the black background)
    GtkWidget *offload = gtk_graphics_offload_new (data.video);
    gtk_graphics_offload_set_black_background (GTK_GRAPHICS_OFFLOAD (offload),
                                               TRUE);
    gtk_graphics_offload_set_enabled (GTK_GRAPHICS_OFFLOAD (offload), TRUE);

    gtk_window_set_child (data.window, offload);

    // Initially we set the picture to show Rygel's logo. It will be swapped
    // out for the sink's paintable in the message handler we connected above
    data.texture = gdk_texture_new_from_resource (LOGO_PATH);
    gtk_picture_set_paintable (GTK_PICTURE (data.video),
                               GDK_PAINTABLE (data.texture));

    // For some convenience, we also hook up a keyboard event controller
    // to be able to react to some keyboard shortcuts
    GtkEventController *key_events = gtk_event_controller_key_new ();
    gtk_widget_add_controller (GTK_WIDGET (data.window), key_events);
    gtk_widget_set_can_focus (data.video, TRUE);
    gtk_widget_grab_focus (data.video);
    g_signal_connect (key_events,
                      "key-released",
                      G_CALLBACK (on_key_released),
                      &data);

    // Then just make the window fullscreen and display it
    gtk_window_fullscreen (data.window);
    gtk_window_present (data.window);

    if (argc >= 2) {
        rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (renderer),
                                          argv[1]);
    } else {
        rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (renderer),
                                          "eth0");
    }

    // Start the main loop and wait for things to happen
    data.loop = g_main_loop_new (NULL, FALSE);
    g_main_loop_run (data.loop);

    gtk_widget_set_visible (GTK_WIDGET (data.window), FALSE);
    g_object_unref (renderer);
    g_object_unref (data.texture);
    g_main_loop_unref (data.loop);
    g_object_unref (data.playbin);
    g_object_unref (data.window);

    return 0;
}
