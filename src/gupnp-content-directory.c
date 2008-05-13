/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
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
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

#include <string.h>
#include <libgupnp/gupnp.h>
#include <libgupnp-av/gupnp-av.h>

#include "gupnp-content-directory.h"
#include "gupnp-media-tracker.h"

G_DEFINE_TYPE (GUPnPContentDirectory,
               gupnp_content_directory,
               GUPNP_TYPE_SERVICE);

struct _GUPnPContentDirectoryPrivate {
        guint32 system_update_id;

        GUPnPMediaTracker *tracker;
};

/* GObject stuff */
static void
gupnp_content_directory_dispose (GObject *object)
{
        GUPnPContentDirectory *content_dir;
        GObjectClass *object_class;

        content_dir = GUPNP_CONTENT_DIRECTORY (object);

        /* Free GUPnP resources */
        if (content_dir->priv->tracker) {
                g_object_unref (content_dir->priv->tracker);
                content_dir->priv->tracker = NULL;
        }

        /* Call super */
        object_class = G_OBJECT_CLASS (gupnp_content_directory_parent_class);
        object_class->dispose (object);
}

static void
gupnp_content_directory_init (GUPnPContentDirectory *content_dir)
{
         content_dir->priv = G_TYPE_INSTANCE_GET_PRIVATE
                                (content_dir,
                                 GUPNP_TYPE_CONTENT_DIRECTORY,
                                 GUPnPContentDirectoryPrivate);
}

static GObject *
gupnp_content_directory_constructor (GType                  type,
                                     guint                  n_construct_params,
                                     GObjectConstructParam *construct_params)
{
        GObject *object;
        GObjectClass *object_class;
        GUPnPContentDirectory *content_dir;
        GUPnPContext *context;
        GError *error;

        object_class = G_OBJECT_CLASS (gupnp_content_directory_parent_class);
        object = object_class->constructor (type,
                                            n_construct_params,
                                            construct_params);

        if (object == NULL)
                return NULL;

        content_dir = GUPNP_CONTENT_DIRECTORY (object);

        error = NULL;
        gupnp_service_signals_autoconnect (GUPNP_SERVICE (content_dir),
                                           NULL,
                                           &error);
        if (error) {
                g_warning ("Error autoconnecting signals: %s",
                           error->message);
                g_error_free (error);
        }

        context = gupnp_service_info_get_context
                                (GUPNP_SERVICE_INFO (content_dir));

        content_dir->priv->tracker = gupnp_media_tracker_new ("0", context);

        return object;
}

static void
gupnp_content_directory_class_init (GUPnPContentDirectoryClass *klass)
{
        GObjectClass *object_class;

        object_class = G_OBJECT_CLASS (klass);

        object_class->dispose = gupnp_content_directory_dispose;
        object_class->constructor = gupnp_content_directory_constructor;

        g_type_class_add_private (klass, sizeof (GUPnPContentDirectoryPrivate));
}

/* Browse action implementation */
void
browse_cb (GUPnPContentDirectory *content_dir,
           GUPnPServiceAction    *action,
           gpointer               user_data)
{
        char *object_id, *browse_flag;
        gboolean browse_metadata;
        char *result, *sort_criteria, *filter;
        guint32 starting_index, requested_count;
        guint32 num_returned, total_matches, update_id;

        /* Handle incoming arguments */
        gupnp_service_action_get (action,
                                  "ObjectID",
                                        G_TYPE_STRING,
                                        &object_id,
                                  "BrowseFlag",
                                        G_TYPE_STRING,
                                        &browse_flag,
                                  "Filter",
                                        G_TYPE_STRING,
                                        &filter,
                                  "StartingIndex",
                                        G_TYPE_UINT,
                                        &starting_index,
                                  "RequestedCount",
                                        G_TYPE_UINT,
                                        &requested_count,
                                  "SortCriteria",
                                        G_TYPE_STRING,
                                        &sort_criteria,
                                  NULL);

        /* BrowseFlag */
        if (browse_flag && !strcmp (browse_flag, "BrowseDirectChildren")) {
                browse_metadata = FALSE;
        } else if (browse_flag && !strcmp (browse_flag, "BrowseMetadata")) {
                browse_metadata = TRUE;
        } else {
                gupnp_service_action_return_error
                        (action, GUPNP_CONTROL_ERROR_INVALID_ARGS, NULL);

                goto OUT;
        }

        /* ObjectID */
        if (!object_id) {
                /* Stupid Xbox */
                gupnp_service_action_get (action,
                                          "ContainerID",
                                          G_TYPE_STRING,
                                          &object_id,
                                          NULL);
                if (!object_id) {
                        gupnp_service_action_return_error
                                (action, 701, "No such object");

                        goto OUT;
                }
        }

        if (browse_metadata) {
                result = gupnp_media_tracker_get_metadata
                                        (content_dir->priv->tracker,
                                         object_id,
                                         filter,
                                         sort_criteria,
                                         &update_id);

                num_returned = 1;
                total_matches = 1;
        } else {
                result = gupnp_media_tracker_browse (content_dir->priv->tracker,
                                                     object_id,
                                                     filter,
                                                     starting_index,
                                                     requested_count,
                                                     sort_criteria,
                                                     &num_returned,
                                                     &total_matches,
                                                     &update_id);
        }

        if (result == NULL) {
                gupnp_service_action_return_error (action,
                                                   701,
                                                   "No such object");

                goto OUT;
        }

        if (update_id == GUPNP_INVALID_UPDATE_ID)
                update_id = content_dir->priv->system_update_id;

        /* Set action return arguments */
        gupnp_service_action_set (action,
                                  "Result",
                                        G_TYPE_STRING,
                                        result,
                                  "NumberReturned",
                                        G_TYPE_UINT,
                                        num_returned,
                                  "TotalMatches",
                                        G_TYPE_UINT,
                                        total_matches,
                                  "UpdateID",
                                        G_TYPE_UINT,
                                        update_id,
                                  NULL);

        gupnp_service_action_return (action);

        g_free (result);
OUT:
        g_free (object_id);
}

