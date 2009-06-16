/*
 * Copyright (C) 2006, 2008 OpenedHand Ltd.
 *
 * OpenedHand Widget Library Video Widget - A GStreamer video GTK+ widget
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 */

#include <gdk/gdkx.h>
#include <gst/gst.h>
#include <gst/interfaces/xoverlay.h>

#include "owl-video-widget.h"

/** TODO
 * o Possibly implement colour balance properties.
 *   xvimagesink supports the following, on a range -1000 - 1000:
 *     - contrast
 *     - brightness
 *     - hue
 *     - saturation
 **/

G_DEFINE_TYPE (OwlVideoWidget,
               owl_video_widget,
               GTK_TYPE_BIN);

struct _OwlVideoWidgetPrivate {
        GstElement *playbin;
        GstXOverlay *overlay;

        GMutex *overlay_lock;

        GdkWindow *dummy_window;

        char *uri;

        gboolean can_seek;

        int buffer_percent;

        int duration;

        gboolean force_aspect_ratio;

        guint tick_timeout_id;
};

enum {
        PROP_0,
        PROP_URI,
        PROP_PLAYING,
        PROP_POSITION,
        PROP_VOLUME,
        PROP_CAN_SEEK,
        PROP_BUFFER_PERCENT,
        PROP_DURATION,
        PROP_FORCE_ASPECT_RATIO
};

enum {
        TAG_LIST_AVAILABLE,
        EOS,
        ERROR,
        LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

#define TICK_TIMEOUT 0.5

/* TODO: Possibly retrieve these through introspection. The problem is that we
 * need them in class_init already. */
#define GST_VOL_DEFAULT 1.0
#define GST_VOL_MAX     4.0

/**
 * Synchronise the force-aspect-ratio property with the videosink.
 **/
static void
sync_force_aspect_ratio (OwlVideoWidget *video_widget)
{
        GObjectClass *class;

        class = G_OBJECT_GET_CLASS (video_widget->priv->overlay);
        
        if (!g_object_class_find_property (class, "force-aspect-ratio")) {
                g_warning ("Unable to find 'force-aspect-ratio' "
                           "property.");

                return;
        } 

        g_object_set (video_widget->priv->overlay,
                      "force-aspect-ratio",
                      video_widget->priv->force_aspect_ratio,
                      NULL);
}

/**
 * Ensures the existance of a dummy window and returns its XID.
 **/
static XID
create_dummy_window (OwlVideoWidget *video_widget)
{
        GdkWindowAttr attributes;

        if (video_widget->priv->dummy_window)
                return GDK_WINDOW_XID (video_widget->priv->dummy_window);

        attributes.width = 0;
        attributes.height = 0;
        attributes.window_type = GDK_WINDOW_TOPLEVEL;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.event_mask = 0;

        video_widget->priv->dummy_window = gdk_window_new (NULL,
                                                           &attributes,
                                                           0);

        /**
         * Sync, so that the window is definetely there when the videosink
         * starts looking at it.
         **/
        XSync (GDK_WINDOW_XDISPLAY (video_widget->priv->dummy_window), FALSE);

        return GDK_WINDOW_XID (video_widget->priv->dummy_window);
}

/**
 * Destroys the dummy window, if any.
 **/
static void
destroy_dummy_window (OwlVideoWidget *video_widget)
{
        if (video_widget->priv->dummy_window) {
                g_object_unref (video_widget->priv->dummy_window);
                video_widget->priv->dummy_window = NULL;
        }
}

/**
 * A message arrived synchronously on the bus: See if the overlay becomes available.
 **/
static GstBusSyncReply
bus_sync_handler_cb (GstBus            *bus,
                     GstMessage        *message,
                     OwlVideoWidget *video_widget)
{

        const GstStructure *str;
        XID xid;

        str = gst_message_get_structure (message);
        if (!str)
                return GST_BUS_PASS;
        
        if (!gst_structure_has_name (str, "prepare-xwindow-id"))
                return GST_BUS_PASS;

        /**
         * Lock.
         **/
        g_mutex_lock (video_widget->priv->overlay_lock);

        gdk_threads_enter ();

        /**
         * Take in the new overlay.
         **/
        if (video_widget->priv->overlay) {
                g_object_remove_weak_pointer
                        (G_OBJECT (video_widget->priv->overlay),
                         (gpointer) &video_widget->priv->overlay);
        }
        
        video_widget->priv->overlay = GST_X_OVERLAY (GST_MESSAGE_SRC (message));

        g_object_add_weak_pointer (G_OBJECT (video_widget->priv->overlay),
                                   (gpointer) &video_widget->priv->overlay);

        g_object_set (video_widget->priv->overlay,
                      "handle-expose", FALSE,
                      NULL);

        sync_force_aspect_ratio (video_widget);

        /**
         * Connect the new overlay to our window.
         **/
        if (GTK_WIDGET_REALIZED (video_widget))
                xid = GDK_WINDOW_XID (GTK_WIDGET (video_widget)->window);
        else
                xid = create_dummy_window (video_widget);

        gst_x_overlay_set_xwindow_id (video_widget->priv->overlay, xid);

        /**
         * And expose.
         **/
        if (GTK_WIDGET_REALIZED (video_widget))
                gst_x_overlay_expose (video_widget->priv->overlay);
        
        /**
         * Unlock.
         **/
        gdk_threads_leave ();
        
        g_mutex_unlock (video_widget->priv->overlay_lock);

        /**
         * Drop this message.
         **/
        gst_message_unref (message);
        
        return GST_BUS_DROP;
}

/**
 * An error occured.
 **/
static void
bus_message_error_cb (GstBus         *bus,
                      GstMessage     *message,
                      OwlVideoWidget *video_widget)
{
        GError *error;

        error = NULL;
        gst_message_parse_error (message,
                                 &error,
                                 NULL);
        
        g_signal_emit (video_widget,
                       signals[ERROR],
                       0,
                       error);

        g_error_free (error);
}

/**
 * End of stream reached.
 **/
static void
bus_message_eos_cb (GstBus         *bus,
                    GstMessage     *message,
                    OwlVideoWidget *video_widget)
{
        /**
         * Make sure UI is in sync.
         **/
        g_object_notify (G_OBJECT (video_widget), "position");

        /**
         * Emit EOS signal.
         **/
        g_signal_emit (video_widget,
                       signals[EOS],
                       0);
}

/**
 * Tag list available.
 **/
static void
bus_message_tag_cb (GstBus         *bus,
                    GstMessage     *message,
                    OwlVideoWidget *video_widget)
{
        GstTagList *tag_list;

        gst_message_parse_tag (message, &tag_list);

        g_signal_emit (video_widget,
                       signals[TAG_LIST_AVAILABLE],
                       0,
                       tag_list);

        gst_tag_list_free (tag_list);
}

/**
 * Buffering information available.
 **/
static void
bus_message_buffering_cb (GstBus         *bus,
                          GstMessage     *message,
                          OwlVideoWidget *video_widget)
{
        const GstStructure *str;

        str = gst_message_get_structure (message);
        if (!str)
                return;

        if (!gst_structure_get_int (str,
                                    "buffer-percent",
                                    &video_widget->priv->buffer_percent))
                return;
        
        g_object_notify (G_OBJECT (video_widget), "buffer-percent");
}

/**
 * Duration information available.
 **/
static void
bus_message_duration_cb (GstBus         *bus,
                         GstMessage     *message,
                         OwlVideoWidget *video_widget)
{
        GstFormat format;
        gint64 duration;

        gst_message_parse_duration (message,
                                    &format,
                                    &duration);

        if (format != GST_FORMAT_TIME)
                return;

        video_widget->priv->duration = duration / GST_SECOND;

        g_object_notify (G_OBJECT (video_widget), "duration");
}

/**
 * A state change occured.
 **/
static void
bus_message_state_change_cb (GstBus         *bus,
                             GstMessage     *message,
                             OwlVideoWidget *video_widget)
{
        gpointer src;
        GstState old_state, new_state;

        src = GST_MESSAGE_SRC (message);
        
        if (src != video_widget->priv->playbin)
                return;

        gst_message_parse_state_changed (message,
                                         &old_state,
                                         &new_state,
                                         NULL);

        if (old_state == GST_STATE_READY &&
            new_state == GST_STATE_PAUSED) {
                GstQuery *query;

                /**
                 * Determine whether we can seek.
                 **/
                query = gst_query_new_seeking (GST_FORMAT_TIME);

                if (gst_element_query (video_widget->priv->playbin, query)) {
                        gst_query_parse_seeking (query,
                                                 NULL,
                                                 &video_widget->priv->can_seek,
                                                 NULL,
                                                 NULL);
                } else {
                        /**
                         * Could not query for ability to seek. Assume
                         * seek is supported.
                         **/

                        video_widget->priv->can_seek = TRUE;
                }

                gst_query_unref (query);
                
                g_object_notify (G_OBJECT (video_widget), "can-seek");

                /**
                 * Determine the duration.
                 **/
                query = gst_query_new_duration (GST_FORMAT_TIME);

                if (gst_element_query (video_widget->priv->playbin, query)) {
                        gint64 duration;

                        gst_query_parse_duration (query,
                                                  NULL,
                                                  &duration);

                        video_widget->priv->duration = duration / GST_SECOND;
                        
                        g_object_notify (G_OBJECT (video_widget), "duration");
                }

                gst_query_unref (query);
        }
}

/**
 * Called every TICK_TIMEOUT secs to notify of a position change.
 **/
static gboolean
tick_timeout (OwlVideoWidget *video_widget)
{
        g_object_notify (G_OBJECT (video_widget), "position");

        return TRUE;
}

/**
 * Constructs the GStreamer pipeline.
 **/
static void
construct_pipeline (OwlVideoWidget *video_widget)
{

        GstElement *videosink, *audiosink;
        GstBus *bus;

        /**
         * playbin.
         **/
        video_widget->priv->playbin =
                gst_element_factory_make ("playbin2", "playbin2");
        if (!video_widget->priv->playbin) {
                /* Try playbin if playbin2 isn't available */
                video_widget->priv->playbin =
                        gst_element_factory_make ("playbin", "playbin");
        }

        if (!video_widget->priv->playbin) {
                g_warning ("No playbin found. Playback will not work.");

                return;
        }

        /**
         * A videosink.
         **/
        videosink = gst_element_factory_make ("gconfvideosink", "videosink");
        if (!videosink) {
                g_warning ("No gconfvideosink found. Trying autovideosink ...");

                videosink = gst_element_factory_make ("autovideosink",
                                                      "videosink");
                if (!videosink) {
                        g_warning ("No autovideosink found. "
                                   "Trying ximagesink ...");

                        videosink = gst_element_factory_make ("ximagesink",
                                                              "videosink");
                        if (!videosink) {
                                g_warning ("No videosink could be found. "
                                           "Video will not be available.");
                        }
                }
        }

        /**
         * An audiosink.
         **/
        audiosink = gst_element_factory_make ("gconfaudiosink", "audiosink");
        if (!audiosink) {
                g_warning ("No gconfaudiosink found. Trying autoaudiosink ...");

                audiosink = gst_element_factory_make ("autoaudiosink",
                                                      "audiosink");
                if (!audiosink) {
                        g_warning ("No autoaudiosink found. "
                                   "Trying alsasink ...");

                        audiosink = gst_element_factory_make ("alsasink",
                                                              "audiosink");
                        if (!audiosink) {
                                g_warning ("No audiosink could be found. "
                                           "Audio will not be available.");
                        }
                }
        }

        /**
         * Click sinks into playbin.
         **/
        g_object_set (G_OBJECT (video_widget->priv->playbin),
                      "video-sink", videosink,
                      "audio-sink", audiosink,
                      NULL);

        /**
         * Connect to signals on bus.
         **/
        bus = gst_pipeline_get_bus (GST_PIPELINE (video_widget->priv->playbin));

        gst_bus_add_signal_watch (bus);

        gst_bus_set_sync_handler (bus,
                                  (GstBusSyncHandler) bus_sync_handler_cb,
                                  video_widget);
        
        g_signal_connect_object (bus,
                                 "message::error",
                                 G_CALLBACK (bus_message_error_cb),
                                 video_widget,
                                 0);
        g_signal_connect_object (bus,
                                 "message::eos",
                                 G_CALLBACK (bus_message_eos_cb),
                                 video_widget,
                                 0);
        g_signal_connect_object (bus,
                                 "message::tag",
                                 G_CALLBACK (bus_message_tag_cb),
                                 video_widget,
                                 0);
        g_signal_connect_object (bus,
                                 "message::buffering",
                                 G_CALLBACK (bus_message_buffering_cb),
                                 video_widget,
                                 0);
        g_signal_connect_object (bus,
                                 "message::duration",
                                 G_CALLBACK (bus_message_duration_cb),
                                 video_widget,
                                 0);
 
        g_signal_connect_object (bus,
                                 "message::state-changed",
                                 G_CALLBACK (bus_message_state_change_cb),
                                 video_widget,
                                 0);

        gst_object_unref (GST_OBJECT (bus));
}

static void
owl_video_widget_init (OwlVideoWidget *video_widget)
{
        /**
         * We do have our own GdkWindow.
         **/
        GTK_WIDGET_UNSET_FLAGS (video_widget, GTK_NO_WINDOW);
        GTK_WIDGET_UNSET_FLAGS (video_widget, GTK_DOUBLE_BUFFERED);

        /**
         * Create pointer to private data.
         **/
        video_widget->priv =
                G_TYPE_INSTANCE_GET_PRIVATE (video_widget,
                                             OWL_TYPE_VIDEO_WIDGET,
                                             OwlVideoWidgetPrivate);

        /**
         * Initialize defaults.
         **/
        video_widget->priv->force_aspect_ratio = TRUE;

        /**
         * Create lock.
         **/
        video_widget->priv->overlay_lock = g_mutex_new ();

        /**
         * Construct GStreamer pipeline: playbin with sinks from GConf.
         **/
        construct_pipeline (video_widget);
}

static void
owl_video_widget_set_property (GObject      *object,
                               guint         property_id,
                               const GValue *value,
                               GParamSpec   *pspec)
{
        OwlVideoWidget *video_widget;

        video_widget = OWL_VIDEO_WIDGET (object);

        switch (property_id) {
        case PROP_URI:
                owl_video_widget_set_uri (video_widget,
                                             g_value_get_string (value));
                break;
        case PROP_PLAYING:
                owl_video_widget_set_playing (video_widget,
                                                 g_value_get_boolean (value));
                break;
        case PROP_POSITION:
                owl_video_widget_set_position (video_widget,
                                                  g_value_get_int (value));
                break;
        case PROP_VOLUME:
                owl_video_widget_set_volume (video_widget,
                                                g_value_get_double (value));
                break;
        case PROP_FORCE_ASPECT_RATIO:
                owl_video_widget_set_force_aspect_ratio
                                               (video_widget,
                                                g_value_get_boolean (value));
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
owl_video_widget_get_property (GObject    *object,
                               guint       property_id,
                               GValue     *value,
                               GParamSpec *pspec)
{
        OwlVideoWidget *video_widget;

        video_widget = OWL_VIDEO_WIDGET (object);

        switch (property_id) {
        case PROP_URI:
                g_value_set_string
                        (value,
                         owl_video_widget_get_uri (video_widget));
                break;
        case PROP_PLAYING:
                g_value_set_boolean
                        (value,
                         owl_video_widget_get_playing (video_widget));
                break;
        case PROP_POSITION:
                g_value_set_int
                        (value,
                         owl_video_widget_get_position (video_widget));
                break;
        case PROP_VOLUME:
                g_value_set_double
                        (value,
                         owl_video_widget_get_volume (video_widget));
                break;
        case PROP_CAN_SEEK:
                g_value_set_boolean
                        (value,
                         owl_video_widget_get_can_seek (video_widget));
                break;
        case PROP_BUFFER_PERCENT:
                g_value_set_int
                        (value,
                         owl_video_widget_get_buffer_percent (video_widget));
                break;
        case PROP_DURATION:
                g_value_set_int
                        (value,
                         owl_video_widget_get_duration (video_widget));
                break;
        case PROP_FORCE_ASPECT_RATIO:
                g_value_set_boolean
                        (value,
                         owl_video_widget_get_force_aspect_ratio
                                                        (video_widget));
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
owl_video_widget_dispose (GObject *object)
{
        OwlVideoWidget *video_widget;
        GObjectClass *object_class;

        video_widget = OWL_VIDEO_WIDGET (object);

        if (video_widget->priv->playbin) {
                gst_element_set_state (video_widget->priv->playbin,
                                       GST_STATE_NULL);

                gst_object_unref (GST_OBJECT (video_widget->priv->playbin));
                video_widget->priv->playbin = NULL;
        }

        if (video_widget->priv->tick_timeout_id > 0) {
                g_source_remove (video_widget->priv->tick_timeout_id);
                video_widget->priv->tick_timeout_id = 0;
        }

        destroy_dummy_window (video_widget);

        object_class = G_OBJECT_CLASS (owl_video_widget_parent_class);
        object_class->dispose (object);
}

static void
owl_video_widget_finalize (GObject *object)
{
        OwlVideoWidget *video_widget;
        GObjectClass *object_class;

        video_widget = OWL_VIDEO_WIDGET (object);

        g_mutex_free (video_widget->priv->overlay_lock);

        g_free (video_widget->priv->uri);

        object_class = G_OBJECT_CLASS (owl_video_widget_parent_class);
        object_class->finalize (object);
}

static void
owl_video_widget_realize (GtkWidget *widget)
{
        OwlVideoWidget *video_widget;
        GdkWindow *parent_window;
        GdkWindowAttr attributes;
        guint attributes_mask;
        int border_width;

        video_widget = OWL_VIDEO_WIDGET (widget);

        /**
         * Mark widget as realized.
         **/
        GTK_WIDGET_SET_FLAGS (widget, GTK_REALIZED);

        /**
         * Lock.
         **/
        g_mutex_lock (video_widget->priv->overlay_lock);

        /**
         * Create our GdkWindow.
         **/
        border_width = GTK_CONTAINER (widget)->border_width;

        attributes.x = widget->allocation.x + border_width;
        attributes.y = widget->allocation.y + border_width;
        attributes.width = widget->allocation.width - border_width * 2;
        attributes.height = widget->allocation.height - border_width * 2;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.visual = gtk_widget_get_visual (widget);
        attributes.colormap = gtk_widget_get_colormap (widget);
        attributes.event_mask = gtk_widget_get_events (widget);
        attributes.event_mask |= GDK_EXPOSURE_MASK;

        attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL | GDK_WA_COLORMAP;

        parent_window = gtk_widget_get_parent_window (widget);
        widget->window = gdk_window_new (parent_window,
                                         &attributes,
                                         attributes_mask);
        gdk_window_set_user_data (widget->window, widget);

        gdk_window_set_back_pixmap (widget->window, NULL, FALSE);

        /**
         * Sync, so that the window is definitely there when the videosink
         * starts looking at it.
         **/
        XSync (GDK_WINDOW_XDISPLAY (widget->window), FALSE);

        /**
         * Connect overlay, if available, to window.
         **/
        if (video_widget->priv->overlay) {
                XID xid;
                
                xid = GDK_WINDOW_XID (widget->window);
                gst_x_overlay_set_xwindow_id (video_widget->priv->overlay, xid);
                gst_x_overlay_expose (video_widget->priv->overlay);

                /**
                 * Destroy dummy window if it was there.
                 **/
                destroy_dummy_window (video_widget);
        }
        
        /**
         * Unlock.
         **/
        g_mutex_unlock (video_widget->priv->overlay_lock);

        /**
         * Attach GtkStyle.
         **/
        widget->style = gtk_style_attach (widget->style, widget->window);
}

static void
owl_video_widget_unrealize (GtkWidget *widget)
{
        OwlVideoWidget *video_widget;
        GtkWidgetClass *widget_class;

        video_widget = OWL_VIDEO_WIDGET (widget);

        /**
         * Lock.
         **/
        g_mutex_lock (video_widget->priv->overlay_lock);

        /**
         * Connect overlay, if available, to hidden window.
         **/
        if (video_widget->priv->overlay) {
                XID xid;

                xid = create_dummy_window (video_widget);
                
                gst_x_overlay_set_xwindow_id (video_widget->priv->overlay, xid);
        }

        /**
         * Unlock.
         **/
        g_mutex_unlock (video_widget->priv->overlay_lock);

        /**
         * Call parent class.
         **/
        widget_class = GTK_WIDGET_CLASS (owl_video_widget_parent_class);
        widget_class->unrealize (widget);
}

static gboolean
owl_video_widget_expose (GtkWidget      *widget,
                         GdkEventExpose *event)
{
        OwlVideoWidget *video_widget;
        GtkWidgetClass *widget_class;

        /* Perform extra exposure compression */
        if (event && event->count > 0)
          return TRUE;
        
        video_widget = OWL_VIDEO_WIDGET (widget);

        /**
         * Only draw if we are drawable.
         **/
        if (!GTK_WIDGET_DRAWABLE (widget))
                return FALSE;

        gdk_draw_rectangle (widget->window, widget->style->black_gc, TRUE,
                            event->area.x, event->area.y,
                            event->area.width, event->area.height);

        /**
         * Lock.
         **/
        g_mutex_lock (video_widget->priv->overlay_lock);

        /**
         * If we have an overlay, forward the expose to GStreamer.
         **/
        if (video_widget->priv->overlay)
                gst_x_overlay_expose (video_widget->priv->overlay);

        /**
         * Unlock.
         **/
        g_mutex_unlock (video_widget->priv->overlay_lock);

        /**
         * Call parent class.
         **/
        widget_class = GTK_WIDGET_CLASS (owl_video_widget_parent_class);
        widget_class->expose_event (widget, event);

        return TRUE;
}

static void
owl_video_widget_size_request (GtkWidget      *widget,
                               GtkRequisition *requisition)
{
        int border_width;
        GtkWidget *child;

        border_width = GTK_CONTAINER (widget)->border_width;

        /**
         * Request width from child.
         **/
        child = GTK_BIN (widget)->child;
        if (child && GTK_WIDGET_VISIBLE (child))
                gtk_widget_size_request (child, requisition);

        requisition->width  += border_width * 2;
        requisition->height += border_width * 2;
}

static void
owl_video_widget_size_allocate (GtkWidget     *widget,
                                GtkAllocation *allocation)
{
        OwlVideoWidget *video_widget;
        int border_width;
        GtkAllocation child_allocation;
        GtkWidget *child;

        video_widget = OWL_VIDEO_WIDGET (widget);

        /**
         * Cache the allocation.
         **/
        widget->allocation = *allocation;

        /**
         * Calculate the size for our GdkWindow and for the child.
         **/
        border_width = GTK_CONTAINER (widget)->border_width;

        child_allocation.x      = allocation->x + border_width;
        child_allocation.y      = allocation->y + border_width;
        child_allocation.width  = allocation->width - border_width * 2;
        child_allocation.height = allocation->height - border_width * 2;

        /**
         * Resize our GdkWindow.
         **/
        if (GTK_WIDGET_REALIZED (widget)) {
                gdk_window_move_resize (widget->window,
                                        child_allocation.x,
                                        child_allocation.y,
                                        child_allocation.width,
                                        child_allocation.height);
        }

        /**
         * Forward the size allocation to our child.
         **/
        child = GTK_BIN (widget)->child;
        if (child && GTK_WIDGET_VISIBLE (child)) {
                /**
                 * The child is positioned relative to its parent.
                 **/
                child_allocation.x = 0;
                child_allocation.y = 0;

                gtk_widget_size_allocate (child, &child_allocation);
        }
}

static void
owl_video_widget_class_init (OwlVideoWidgetClass *klass)
{
        GObjectClass *object_class;
        GtkWidgetClass *widget_class;

	object_class = G_OBJECT_CLASS (klass);

	object_class->set_property = owl_video_widget_set_property;
	object_class->get_property = owl_video_widget_get_property;
	object_class->dispose      = owl_video_widget_dispose;
	object_class->finalize     = owl_video_widget_finalize;

        widget_class = GTK_WIDGET_CLASS (klass);

        widget_class->realize       = owl_video_widget_realize;
        widget_class->unrealize     = owl_video_widget_unrealize;
        widget_class->expose_event  = owl_video_widget_expose;
        widget_class->size_request  = owl_video_widget_size_request;
        widget_class->size_allocate = owl_video_widget_size_allocate;

        g_type_class_add_private (klass, sizeof (OwlVideoWidgetPrivate));

        g_object_class_install_property
                (object_class,
                 PROP_URI,
                 g_param_spec_string
                         ("uri",
                          "URI",
                          "The loaded URI.",
                          NULL,
                          G_PARAM_READWRITE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_PLAYING,
                 g_param_spec_boolean
                         ("playing",
                          "Playing",
                          "TRUE if playing.",
                          FALSE,
                          G_PARAM_READWRITE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_POSITION,
                 g_param_spec_int
                         ("position",
                          "Position",
                          "The position in the current stream in seconds.",
                          0, G_MAXINT, 0,
                          G_PARAM_READWRITE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_VOLUME,
                 g_param_spec_double
                         ("volume",
                          "Volume",
                          "The audio volume.",
                          0, GST_VOL_MAX, GST_VOL_DEFAULT,
                          G_PARAM_READWRITE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_CAN_SEEK,
                 g_param_spec_boolean
                         ("can-seek",
                          "Can seek",
                          "TRUE if the current stream is seekable.",
                          FALSE,
                          G_PARAM_READABLE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_BUFFER_PERCENT,
                 g_param_spec_int
                         ("buffer-percent",
                          "Buffer percent",
                          "The percentage the current stream buffer is filled.",
                          0, 100, 0,
                          G_PARAM_READABLE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_DURATION,
                 g_param_spec_int
                         ("duration",
                          "Duration",
                          "The duration of the current stream in seconds.",
                          0, G_MAXINT, 0,
                          G_PARAM_READABLE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        g_object_class_install_property
                (object_class,
                 PROP_FORCE_ASPECT_RATIO,
                 g_param_spec_boolean
                         ("force-aspect-ratio",
                          "Force aspect ratio",
                          "TRUE to force the image's aspect ratio to be "
                          "honoured.",
                          TRUE,
                          G_PARAM_READWRITE |
                          G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK |
                          G_PARAM_STATIC_BLURB));

        signals[TAG_LIST_AVAILABLE] =
                g_signal_new ("tag-list-available",
                              OWL_TYPE_VIDEO_WIDGET,
                              G_SIGNAL_RUN_LAST,
                              G_STRUCT_OFFSET (OwlVideoWidgetClass,
                                               tag_list_available),
                              NULL, NULL,
                              g_cclosure_marshal_VOID__POINTER,
                              G_TYPE_NONE, 1, G_TYPE_POINTER);

        signals[EOS] =
                g_signal_new ("eos",
                              OWL_TYPE_VIDEO_WIDGET,
                              G_SIGNAL_RUN_LAST,
                              G_STRUCT_OFFSET (OwlVideoWidgetClass,
                                               eos),
                              NULL, NULL,
                              g_cclosure_marshal_VOID__VOID,
                              G_TYPE_NONE, 0);

        signals[ERROR] =
                g_signal_new ("error",
                              OWL_TYPE_VIDEO_WIDGET,
                              G_SIGNAL_RUN_LAST,
                              G_STRUCT_OFFSET (OwlVideoWidgetClass,
                                               error),
                              NULL, NULL,
                              g_cclosure_marshal_VOID__POINTER,
                              G_TYPE_NONE, 1, G_TYPE_POINTER);
}

/**
 * owl_video_widget_new
 *
 * Return value: A new #OwlVideoWidget.
 **/
GtkWidget *
owl_video_widget_new (void)
{
        return g_object_new (OWL_TYPE_VIDEO_WIDGET, NULL);
}

/**
 * owl_video_widget_set_uri
 * @video_widget: A #OwlVideoWidget
 * @uri: A URI
 *
 * Loads @uri.
 **/
void
owl_video_widget_set_uri (OwlVideoWidget *video_widget,
                          const char     *uri)
{
        GstState state, pending;

        g_return_if_fail (OWL_IS_VIDEO_WIDGET (video_widget));

        if (!video_widget->priv->playbin)
                return;

        g_free (video_widget->priv->uri);

        if (uri) {
                video_widget->priv->uri = g_strdup (uri);

                /**
                 * Ensure the tick timeout is installed.
                 * 
                 * We also have it installed in PAUSED state, because
                 * seeks etc may have a delayed effect on the position.
                 **/
                if (video_widget->priv->tick_timeout_id == 0) {
                        video_widget->priv->tick_timeout_id =
                                g_timeout_add (TICK_TIMEOUT * 1000,
                                               (GSourceFunc) tick_timeout,
                                               video_widget);
                }
        } else {
                video_widget->priv->uri = NULL;

                /**
                 * Remove tick timeout.
                 **/
                if (video_widget->priv->tick_timeout_id > 0) {
                        g_source_remove (video_widget->priv->tick_timeout_id);
                        video_widget->priv->tick_timeout_id = 0;
                }
        }

        /**
         * Reset properties.
         **/
        video_widget->priv->can_seek = FALSE;
        video_widget->priv->duration = 0;

        /**
         * Store old state.
         **/
        gst_element_get_state (video_widget->priv->playbin,
                               &state,
                               &pending,
                               0);
        if (pending)
                state = pending;

        /**
         * State to NULL.
         **/
        gst_element_set_state (video_widget->priv->playbin, GST_STATE_NULL);

        /**
         * Set new URI.
         **/
        g_object_set (video_widget->priv->playbin,
                      "uri", uri,
                      NULL);
        
        /**
         * Restore state.
         **/
        if (uri)
                gst_element_set_state (video_widget->priv->playbin, state);

        /**
         * Emit notififications for all these to make sure UI is not showing
         * any properties of the old URI.
         **/
        g_object_notify (G_OBJECT (video_widget), "uri");
        g_object_notify (G_OBJECT (video_widget), "can-seek");
        g_object_notify (G_OBJECT (video_widget), "duration");
        g_object_notify (G_OBJECT (video_widget), "position");
}

/**
 * owl_video_widget_get_uri
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: The loaded URI, or NULL if none set.
 **/
const char *
owl_video_widget_get_uri (OwlVideoWidget *video_widget)
{
        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), NULL);

        return video_widget->priv->uri;
}

/**
 * owl_video_widget_set_playing
 * @video_widget: A #OwlVideoWidget
 * @playing: TRUE if @video_widget should be playing, FALSE otherwise
 *
 * Sets the playback state of @video_widget to @playing.
 **/
void
owl_video_widget_set_playing (OwlVideoWidget *video_widget,
                              gboolean        playing)
{
        g_return_if_fail (OWL_IS_VIDEO_WIDGET (video_widget));

        if (!video_widget->priv->playbin)
                return;
        
        /**
         * Choose the correct state for the pipeline.
         **/
        if (video_widget->priv->uri) {
                GstState state;

                if (playing)
                        state = GST_STATE_PLAYING;
                else
                        state = GST_STATE_PAUSED;

                gst_element_set_state (video_widget->priv->playbin, state);
        } else {
                if (playing)
                        g_warning ("Tried to play, but no URI is loaded.");

                /**
                 * Do nothing.
                 **/
        }

        g_object_notify (G_OBJECT (video_widget), "playing");

        /**
         * Make sure UI is in sync.
         **/
        g_object_notify (G_OBJECT (video_widget), "position");
}

/**
 * owl_video_widget_get_playing
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: TRUE if @video_widget is playing.
 **/
gboolean
owl_video_widget_get_playing (OwlVideoWidget *video_widget)
{
        GstState state, pending;

        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), FALSE);

        if (!video_widget->priv->playbin)
                return FALSE;

        gst_element_get_state (video_widget->priv->playbin,
                               &state,
                               &pending,
                               0);

        if (pending)
                return (pending == GST_STATE_PLAYING);
        else
                return (state == GST_STATE_PLAYING);
}

/**
 * owl_video_widget_set_position
 * @video_widget: A #OwlVideoWidget
 * @position: The position in the current stream in seconds.
 *
 * Sets the position in the current stream to @position.
 **/
void
owl_video_widget_set_position (OwlVideoWidget *video_widget,
                               int             position)
{
        GstState state, pending;

        g_return_if_fail (OWL_IS_VIDEO_WIDGET (video_widget));

        if (!video_widget->priv->playbin)
                return;

        /**
         * Store old state.
         **/
        gst_element_get_state (video_widget->priv->playbin,
                               &state,
                               &pending,
                               0);
        if (pending)
                state = pending;

        /**
         * State to PAUSED.
         **/
        gst_element_set_state (video_widget->priv->playbin, GST_STATE_PAUSED);
        
        /**
         * Perform the seek.
         **/
        gst_element_seek (video_widget->priv->playbin,
                          1.0, GST_FORMAT_TIME,
                          GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT,
                          GST_SEEK_TYPE_SET, position * GST_SECOND,
                          GST_SEEK_TYPE_NONE, GST_CLOCK_TIME_NONE);
        /**
         * Restore state.
         **/
        gst_element_set_state (video_widget->priv->playbin, state);
}

/**
 * owl_video_widget_get_position
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: The position in the current file in seconds.
 **/
int
owl_video_widget_get_position (OwlVideoWidget *video_widget)
{
        GstQuery *query;
        gint64 position;
       
        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), -1);

        if (!video_widget->priv->playbin)
                return -1;

        query = gst_query_new_position (GST_FORMAT_TIME);

        if (gst_element_query (video_widget->priv->playbin, query)) {
                gst_query_parse_position (query,
                                          NULL,
                                          &position);
        } else
                position = 0;

        gst_query_unref (query);

        return (position / GST_SECOND);
}

/**
 * owl_video_widget_set_volume
 * @video_widget: A #OwlVideoWidget
 * @volume: The audio volume to set, in the range 0.0 - 4.0.
 *
 * Sets the current audio volume to @volume.
 **/
void
owl_video_widget_set_volume (OwlVideoWidget *video_widget,
                             double          volume)
{
        g_return_if_fail (OWL_IS_VIDEO_WIDGET (video_widget));
        g_return_if_fail (volume >= 0.0 && volume <= GST_VOL_MAX);

        if (!video_widget->priv->playbin)
                return;

        g_object_set (G_OBJECT (video_widget->priv->playbin),
                      "volume", volume,
                      NULL);
        
        g_object_notify (G_OBJECT (video_widget), "volume");
}

/**
 * owl_video_widget_get_volume
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: The current audio volume, in the range 0.0 - 4.0.
 **/
double
owl_video_widget_get_volume (OwlVideoWidget *video_widget)
{
        double volume;

        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), 0);

        if (!video_widget->priv->playbin)
                return 0.0;

        g_object_get (video_widget->priv->playbin,
                      "volume", &volume,
                      NULL);

        return volume;
}

/**
 * owl_video_widget_get_can_seek
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: TRUE if the current stream is seekable.
 **/
gboolean
owl_video_widget_get_can_seek (OwlVideoWidget *video_widget)
{
        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), FALSE);

        return video_widget->priv->can_seek;
}

/**
 * owl_video_widget_get_buffer_percent
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: Percentage the current stream buffer is filled.
 **/
int
owl_video_widget_get_buffer_percent (OwlVideoWidget *video_widget)
{
        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), -1);

        return video_widget->priv->buffer_percent;
}

/**
 * owl_video_widget_get_duration
 * @video_widget: A #OwlVideoWidget
 *
 * Return value: The duration of the current stream in seconds.
 **/
int
owl_video_widget_get_duration (OwlVideoWidget *video_widget)
{
        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), -1);

        return video_widget->priv->duration;
}

/**
 * owl_video_widget_set_force_aspect_ratio
 * @video_widget: A #OwlVideoWidget
 * @force_aspect_ratio: TRUE to force the image's aspect ratio to be
 * honoured.
 *
 * If @force_aspect_ratio is TRUE, sets the image's aspect ratio to be
 * honoured.
 **/
void
owl_video_widget_set_force_aspect_ratio (OwlVideoWidget *video_widget,
                                         gboolean        force_aspect_ratio)
{
        g_return_if_fail (OWL_IS_VIDEO_WIDGET (video_widget));

        if (video_widget->priv->force_aspect_ratio == force_aspect_ratio)
                return;

        video_widget->priv->force_aspect_ratio = force_aspect_ratio;

        g_mutex_lock (video_widget->priv->overlay_lock);

        if (video_widget->priv->overlay)
                sync_force_aspect_ratio (video_widget);

        g_mutex_unlock (video_widget->priv->overlay_lock);

        g_object_notify (G_OBJECT (video_widget), "force-aspect-ratio");
}

/**
 * owl_video_widget_get_force_aspect_ratio
 * @video_widget: A #OwlVideoWidget
 * 
 * Return value: TRUE if the image's aspect ratio is being honoured.
 **/
gboolean
owl_video_widget_get_force_aspect_ratio (OwlVideoWidget *video_widget)
{
        g_return_val_if_fail (OWL_IS_VIDEO_WIDGET (video_widget), FALSE);

        return video_widget->priv->force_aspect_ratio;
}
