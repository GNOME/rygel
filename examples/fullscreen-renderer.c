/*
 * Copyright (C) 2012 Openismus GmbH.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *
 * This file is part of Rygel.
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

/*
 * Demo application for librygel-renderer-gst.
 *
 * Creates a simple stand-alone UPnP renderer that renders any visual content
 * fullscreen.
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

#include <gst/video/videooverlay.h>
#include <gdk/gdkx.h>
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>

#include "rygel-renderer-gst.h"
#include "rygel-core.h"

struct _MainData {
    GtkWindow *window;
    GtkWidget *video;
    GstElement *playbin;
};
typedef struct _MainData MainData;

static void on_realize (GtkWidget *widget, gpointer user_data)
{
    GdkWindow *window;
    guintptr window_handle;
    MainData *data = (MainData *) user_data;

    window = gtk_widget_get_window (widget);
    if (!gdk_window_ensure_native (window))
        g_error ("Could not create native window for overlay");

    window_handle = GDK_WINDOW_XID (window);
    gst_video_overlay_set_window_handle (GST_VIDEO_OVERLAY (data->playbin),
                                         window_handle);
}

static gboolean on_draw (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
    MainData *data = (MainData *) user_data;
    GstState state;

    gst_element_get_state (data->playbin, &state, NULL, GST_CLOCK_TIME_NONE);

    if (state < GST_STATE_PAUSED) {
        gint width, height;

        width = gtk_widget_get_allocated_width (widget);
        height = gtk_widget_get_allocated_height (widget);

        cairo_set_source_rgb (cr, 0, 0, 0);
        cairo_rectangle (cr, 0, 0, width, height);
        cairo_fill (cr);
    }
}

static gboolean on_key_released (GtkWidget *widget,
                             GdkEvent *event,
                             gpointer user_data)
{
    GdkEventKey *key_event = (GdkEventKey *) event;

    switch (key_event->keyval) {
        case GDK_KEY_Escape:
        case GDK_KEY_q:
        case GDK_KEY_Q:
            gtk_main_quit ();

            return TRUE;
        default:
            return FALSE;
    }
}

int main (int argc, char *argv[])
{
    RygelPlaybinRenderer *renderer;
    GError *error = NULL;
    GMainLoop *loop;
    MainData data;
    GdkCursor *cursor;

    gtk_init (&argc, &argv);
    gst_init (&argc, &argv);

    g_set_application_name ("Rygel-Fullscreen-Renderer");

    renderer = rygel_playbin_renderer_new ("LibRygel renderer demo");
    data.playbin = rygel_playbin_renderer_get_playbin (renderer);

    data.window = GTK_WINDOW (gtk_window_new (GTK_WINDOW_TOPLEVEL));
    data.video = gtk_drawing_area_new ();
    gtk_widget_set_double_buffered (data.video, FALSE);
    gtk_container_add (GTK_CONTAINER (data.window), data.video);
    g_signal_connect (data.video, "realize", G_CALLBACK (on_realize), &data);
    gtk_widget_add_events (data.video,
                           GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK);
    gtk_widget_set_can_focus (data.video, TRUE);
    gtk_widget_grab_focus (data.video);
    g_signal_connect (data.video,
                      "draw",
                      G_CALLBACK (on_draw),
                      &data);
    g_signal_connect (data.video,
                      "key-release-event",
                      G_CALLBACK (on_key_released),
                      &data);
    gtk_window_fullscreen (data.window);
    gtk_widget_show_all (GTK_WIDGET (data.window));
    cursor = gdk_cursor_new_for_display (gtk_widget_get_display (data.video),
                                         GDK_BLANK_CURSOR);
    gdk_window_set_cursor (gtk_widget_get_window (data.video), cursor);

    if (argc >= 2) {
        rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (renderer), argv[1]);
    } else {
        rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (renderer), "eth0");
    }

    gtk_main ();
    gtk_widget_hide (GTK_WIDGET (data.window));
    g_object_unref (renderer);

    return 0;
}
