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

#include "gupnp-media-server.h"
#include "gupnp-media-tracker.h"

#define HOME_DIR_ALIAS "/media"

G_DEFINE_TYPE (GUPnPMediaServer,
               gupnp_media_server,
               GUPNP_TYPE_ROOT_DEVICE);

struct _GUPnPMediaServerPrivate {
        guint32 system_update_id;

        GUPnPService *content_dir;

        GUPnPMediaTracker *tracker;
};

/* GObject stuff */
static void
gupnp_media_server_dispose (GObject *object)
{
        GUPnPMediaServer *server;
        GObjectClass *object_class;

        server = GUPNP_MEDIA_SERVER (object);

        /* Free GUPnP resources */
        if (server->priv->tracker) {
                g_object_unref (server->priv->tracker);
                server->priv->tracker = NULL;
        }
        if (server->priv->content_dir) {
                g_object_unref (server->priv->content_dir);
                server->priv->content_dir = NULL;
        }

        /* Call super */
        object_class = G_OBJECT_CLASS (gupnp_media_server_parent_class);
        object_class->dispose (object);
}

static void
gupnp_media_server_init (GUPnPMediaServer *server)
{
         server->priv = G_TYPE_INSTANCE_GET_PRIVATE (server,
                                                     GUPNP_TYPE_MEDIA_SERVER,
                                                     GUPnPMediaServerPrivate);
}

static GObject *
gupnp_media_server_constructor (GType                  type,
                                guint                  n_construct_params,
                                GObjectConstructParam *construct_params)
{
        GObject *object;
        GObjectClass *object_class;
        GUPnPMediaServer *server;
        GUPnPServiceInfo *service;
        GUPnPContext *context;

        object_class = G_OBJECT_CLASS (gupnp_media_server_parent_class);
        object = object_class->constructor (type,
                                            n_construct_params,
                                            construct_params);

        if (object == NULL)
                return NULL;

        server = GUPNP_MEDIA_SERVER (object);

        /* Connect ContentDirectory signals */
        service = gupnp_device_info_get_service
                        (GUPNP_DEVICE_INFO (server),
                         "urn:schemas-upnp-org:service:ContentDirectory:2");
        if (service != NULL) {
                GError *error;

                server->priv->content_dir = GUPNP_SERVICE (service);

                error = NULL;
                gupnp_service_signals_autoconnect (server->priv->content_dir,
                                                   server,
                                                   &error);
                if (error) {
                        g_warning ("Error autoconnecting signals: %s",
                                   error->message);
                        g_error_free (error);
                }
        }

        context = gupnp_device_info_get_context (GUPNP_DEVICE_INFO (server));

        server->priv->tracker = gupnp_media_tracker_new ("0", context);

        return object;
}

static void
gupnp_media_server_class_init (GUPnPMediaServerClass *klass)
{
        GObjectClass *object_class;

        object_class = G_OBJECT_CLASS (klass);

        object_class->dispose = gupnp_media_server_dispose;
        object_class->constructor = gupnp_media_server_constructor;

        g_type_class_add_private (klass, sizeof (GUPnPMediaServerPrivate));
}

/* Browse action implementation */
void
browse_cb (GUPnPService       *service,
           GUPnPServiceAction *action,
           gpointer            user_data)
{
        GUPnPMediaServer *server;
        char *object_id, *browse_flag;
        gboolean browse_metadata;
        char *result, *sort_criteria, *filter;
        guint32 starting_index, requested_count;
        guint32 num_returned, total_matches, update_id;

        server = GUPNP_MEDIA_SERVER (user_data);

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
                gupnp_service_action_return_error
                        (action, 701, "No such object");

                goto OUT;
        }

        if (browse_metadata) {
                result = gupnp_media_tracker_get_metadata
                                        (server->priv->tracker,
                                         object_id,
                                         filter,
                                         sort_criteria,
                                         &update_id);

                num_returned = 1;
                total_matches = 1;
        } else {
                result = gupnp_media_tracker_browse (server->priv->tracker,
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
                update_id = server->priv->system_update_id;

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

GUPnPMediaServer *
gupnp_media_server_new (GUPnPContext *context,
                        xmlDoc       *description_doc,
                        const char   *relative_location)
{
        GUPnPResourceFactory *factory;

        factory = gupnp_resource_factory_get_default ();

        return g_object_new (GUPNP_TYPE_MEDIA_SERVER,
                             "context", context,
                             "resource-factory", factory,
                             "root-device", NULL,
                             "description-doc", description_doc,
                             "relative-location", relative_location,
                             NULL);
}

