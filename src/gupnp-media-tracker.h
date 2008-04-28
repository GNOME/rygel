/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#ifndef __GUPNP_MEDIA_TRACKER_H__
#define __GUPNP_MEDIA_TRACKER_H__

#include <libgupnp/gupnp.h>

#define GUPNP_MAX_UPDATE_ID     G_MAXUINT32 - 1
#define GUPNP_INVALID_UPDATE_ID G_MAXUINT32

G_BEGIN_DECLS

GType
gupnp_media_tracker_get_type (void) G_GNUC_CONST;

#define GUPNP_TYPE_MEDIA_TRACKER \
                (gupnp_media_tracker_get_type ())
#define GUPNP_MEDIA_TRACKER(obj) \
                (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
                 GUPNP_TYPE_MEDIA_TRACKER, \
                 GUPnPMediaTracker))
#define GUPNP_MEDIA_TRACKER_CLASS(obj) \
                (G_TYPE_CHECK_CLASS_CAST ((obj), \
                 GUPNP_TYPE_MEDIA_TRACKER, \
                 GUPnPMediaTrackerClass))
#define GUPNP_IS_MEDIA_TRACKER(obj) \
                (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
                 GUPNP_TYPE_MEDIA_TRACKER))
#define GUPNP_IS_MEDIA_TRACKER_CLASS(obj) \
                (G_TYPE_CHECK_CLASS_TYPE ((obj), \
                 GUPNP_TYPE_MEDIA_TRACKER))
#define GUPNP_MEDIA_TRACKER_GET_CLASS(obj) \
                (G_TYPE_INSTANCE_GET_CLASS ((obj), \
                 GUPNP_TYPE_MEDIA_TRACKER, \
                 GUPnPMediaTrackerClass))

typedef struct _GUPnPMediaTrackerPrivate GUPnPMediaTrackerPrivate;

typedef struct {
        GObject parent;

        GUPnPMediaTrackerPrivate *priv;
} GUPnPMediaTracker;

typedef struct {
        GObjectClass parent_class;

        /* future padding */
        void (* _gupnp_reserved1) (void);
        void (* _gupnp_reserved2) (void);
        void (* _gupnp_reserved3) (void);
        void (* _gupnp_reserved4) (void);
} GUPnPMediaTrackerClass;

GUPnPMediaTracker *
gupnp_media_tracker_new             (const char   *root_id,
                                     GUPnPContext *context);

char *
gupnp_media_tracker_browse          (GUPnPMediaTracker *tracker,
                                     const char        *container_id,
                                     const char        *filter,
                                     guint32            starting_index,
                                     guint32            requested_count,
                                     const char        *sort_criteria,
                                     guint32           *number_returned,
                                     guint32           *total_matches,
                                     guint32           *update_id);

char *
gupnp_media_tracker_get_metadata    (GUPnPMediaTracker *tracker,
                                     const char        *object_id,
                                     const char        *filter,
                                     const char        *sort_criteria,
                                     guint32           *update_id);

G_END_DECLS

#endif /* __GUPNP_MEDIA_TRACKER_H__ */
