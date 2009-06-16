/*
 * Copyright (C) 2006 OpenedHand Ltd.
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

#ifndef __OWL_VIDEO_WIDGET_H__
#define __OWL_VIDEO_WIDGET_H__

#include <gtk/gtkbin.h>
#include <gst/gsttaglist.h>

G_BEGIN_DECLS

#define OWL_TYPE_VIDEO_WIDGET \
                (owl_video_widget_get_type ())
#define OWL_VIDEO_WIDGET(obj) \
                (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
                 OWL_TYPE_VIDEO_WIDGET, \
                 OwlVideoWidget))
#define OWL_VIDEO_WIDGET_CLASS(klass) \
                (G_TYPE_CHECK_CLASS_CAST ((klass), \
                 OWL_TYPE_VIDEO_WIDGET, \
                 OwlVideoWidgetClass))
#define OWL_IS_VIDEO_WIDGET(obj) \
                (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
                 OWL_TYPE_VIDEO_WIDGET))
#define OWL_IS_VIDEO_WIDGET_CLASS(klass) \
                (G_TYPE_CHECK_CLASS_TYPE ((klass), \
                 OWL_TYPE_VIDEO_WIDGET))
#define OWL_VIDEO_WIDGET_GET_CLASS(obj) \
                (G_TYPE_INSTANCE_GET_CLASS ((obj), \
                 OWL_TYPE_VIDEO_WIDGET, \
                 OwlVideoWidgetClass))

typedef struct _OwlVideoWidgetPrivate OwlVideoWidgetPrivate;

typedef struct {
        GtkBin parent;

        OwlVideoWidgetPrivate *priv;
} OwlVideoWidget;

typedef struct {
        GtkBinClass parent_class;

        /* Signals */
        void (* tag_list_available) (OwlVideoWidget *video_widget,
                                     GstTagList     *tag_list);
        void (* eos)                (OwlVideoWidget *video_widget);
        void (* error)              (OwlVideoWidget *video_widget,
                                     GError         *error);
        
        /* Future padding */
        void (* _owl_reserved1) (void);
        void (* _owl_reserved2) (void);
        void (* _owl_reserved3) (void);
        void (* _owl_reserved4) (void);
} OwlVideoWidgetClass;

GType
owl_video_widget_get_type               (void) G_GNUC_CONST;

GtkWidget *
owl_video_widget_new                    (void);

void
owl_video_widget_set_uri                (OwlVideoWidget *video_widget,
                                         const char     *uri);

const char *
owl_video_widget_get_uri                (OwlVideoWidget *video_widget);

void
owl_video_widget_set_playing            (OwlVideoWidget *video_widget,
                                         gboolean        playing);

gboolean
owl_video_widget_get_playing            (OwlVideoWidget *video_widget);

void
owl_video_widget_set_position           (OwlVideoWidget *video_widget,
                                         int             position);

int
owl_video_widget_get_position           (OwlVideoWidget *video_widget);

void
owl_video_widget_set_volume             (OwlVideoWidget *video_widget,
                                         double          volume);

double
owl_video_widget_get_volume             (OwlVideoWidget *video_widget);

gboolean
owl_video_widget_get_can_seek           (OwlVideoWidget *video_widget);

int
owl_video_widget_get_buffer_percent     (OwlVideoWidget *video_widget);

int
owl_video_widget_get_duration           (OwlVideoWidget *video_widget);

void
owl_video_widget_set_force_aspect_ratio (OwlVideoWidget *video_widget,
                                         gboolean        force_aspect_ratio);

gboolean
owl_video_widget_get_force_aspect_ratio (OwlVideoWidget *video_widget);

G_END_DECLS

#endif /* __OWL_VIDEO_WIDGET_H__ */
