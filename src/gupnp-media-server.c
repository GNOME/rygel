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

G_DEFINE_TYPE (GUPnPMediaServer,
               gupnp_media_server,
               GUPNP_TYPE_ROOT_DEVICE);

struct _GUPnPMediaServerPrivate {
        guint32 system_update_id;

        GUPnPService *content_dir;

        GUPnPDIDLLiteWriter *didl_writer;
        GUPnPSearchCriteriaParser *search_parser;
};

/* Hard-coded items (mime, title, path) */
char *items[3][4] = {
        { "4000",
          "audio/mpeg",
          "Maa",
          "/home/zeenix/entertainment/songs/Maa.mp3" },
        { "4001",
          "audio/mpeg",
          "Hoo",
          "/home/zeenix/entertainment/songs/Ho.mp3" },
        { NULL }
};

/* GObject stuff */
static void
gupnp_media_server_dispose (GObject *object)
{
        GUPnPMediaServer *server;
        GObjectClass *object_class;

        server = GUPNP_MEDIA_SERVER (object);

        /* Free GUPnP resources */
        if (server->priv->search_parser) {
                g_object_unref (server->priv->search_parser);
                server->priv->search_parser = NULL;
        }

        if (server->priv->didl_writer) {
                g_object_unref (server->priv->didl_writer);
                server->priv->didl_writer = NULL;
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

         /* Create a new DIDL-Lite writer */
        server->priv->didl_writer = gupnp_didl_lite_writer_new ();

        /* Create a new search criteria parser */
        server->priv->search_parser = gupnp_search_criteria_parser_new ();
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

static void
add_root_container (GUPnPDIDLLiteWriter *didl_writer)
{
        guint child_count;

        /* Count items */
        for (child_count = 0; items[child_count][0]; child_count++);

        gupnp_didl_lite_writer_start_container (didl_writer,
                                                "0",
                                                "-1",
                                                child_count,
                                                FALSE,
                                                FALSE);

        gupnp_didl_lite_writer_add_string
                        (didl_writer,
                         "class",
                         GUPNP_DIDL_LITE_WRITER_NAMESPACE_UPNP,
                         NULL,
                         "object.container.storageFolder");

        /* End of Container */
        gupnp_didl_lite_writer_end_container (didl_writer);
}

static void
add_item (GUPnPContext        *context,
          GUPnPDIDLLiteWriter *didl_writer,
          const char          *id,
          const char          *parent_id,
          const char          *mime,
          const char          *title,
          const char          *path)
{
        GUPnPDIDLLiteResource res;

        gupnp_didl_lite_writer_start_item (didl_writer,
                                           id,
                                           parent_id,
                                           NULL,
                                           FALSE);

        /* Add fields */
        gupnp_didl_lite_writer_add_string (didl_writer,
                                           "title",
                                           GUPNP_DIDL_LITE_WRITER_NAMESPACE_DC,
                                           NULL,
                                           title);

        gupnp_didl_lite_writer_add_string
                        (didl_writer,
                         "class",
                         GUPNP_DIDL_LITE_WRITER_NAMESPACE_UPNP,
                         NULL,
                         "object.item.audioItem.musicTrack");

        gupnp_didl_lite_writer_add_string
                        (didl_writer,
                         "album",
                         GUPNP_DIDL_LITE_WRITER_NAMESPACE_UPNP,
                         NULL,
                         "Some album");

        /* Add resource data */
        gupnp_didl_lite_resource_reset (&res);

        /* URI */
        res.uri = g_strdup_printf ("http://%s:%d%s",
                                   gupnp_context_get_host_ip (context),
                                   gupnp_context_get_port (context),
                                   path);

        /* Protocol info */
        res.protocol_info = g_strdup_printf ("http-get:*:%s:*", mime);

        gupnp_didl_lite_writer_add_res (didl_writer, &res);

        /* Cleanup */
        g_free (res.protocol_info);
        g_free (res.uri);

        /* End of item */
        gupnp_didl_lite_writer_end_item (didl_writer);
}

static char *
browse_direct_children (GUPnPMediaServer *server, guint *num_returned)
{
        GUPnPContext *context;
        const char *didl;
        char *result;
        guint i;

        context = gupnp_device_info_get_context (GUPNP_DEVICE_INFO (server));

        /* Start DIDL-Lite fragment */
        gupnp_didl_lite_writer_start_didl_lite (server->priv->didl_writer,
                                                NULL,
                                                NULL,
                                                TRUE);
        /* Add items */
        for (i = 0; items[i][0]; i++)
                add_item (context,
                          server->priv->didl_writer,
                          items[i][0],
                          "0",
                          items[i][1],
                          items[i][2],
                          items[i][3]);

        /* End DIDL-Lite fragment */
        gupnp_didl_lite_writer_end_didl_lite (server->priv->didl_writer);

        /* Retrieve generated string */
        didl = gupnp_didl_lite_writer_get_string (server->priv->didl_writer);
        result = g_strdup (didl);

        /* Reset the parser state */
        gupnp_didl_lite_writer_reset (server->priv->didl_writer);

        *num_returned = i;

        return result;
}

static char *
get_metadata (GUPnPMediaServer *server,
              const char       *object_id,
              guint            *num_returned)
{
        GUPnPContext *context;
        char *result;
        guint i;

        context = gupnp_device_info_get_context (GUPNP_DEVICE_INFO (server));

        /* Start DIDL-Lite fragment */
        gupnp_didl_lite_writer_start_didl_lite (server->priv->didl_writer,
                                                NULL,
                                                NULL,
                                                TRUE);
        *num_returned = 0;
        if (strcmp (object_id, "0") == 0) {
                        add_root_container (server->priv->didl_writer);

                        *num_returned = 1;
        } else {
                /* Find and add the item */
                for (i = 0; items[i][0]; i++) {
                        if (strcmp (object_id, items[i][0]) == 0) {
                                add_item (context,
                                          server->priv->didl_writer,
                                          items[i][0],
                                          "0",
                                          items[i][1],
                                          items[i][2],
                                          items[i][3]);

                                *num_returned = 1;

                                break;
                        }
                }
        }

        if (*num_returned != 0) {
                const char *didl;

                /* End DIDL-Lite fragment */
                gupnp_didl_lite_writer_end_didl_lite
                                        (server->priv->didl_writer);

                /* Retrieve generated string */
                didl = gupnp_didl_lite_writer_get_string
                                        (server->priv->didl_writer);
                result = g_strdup (didl);
        } else
                result = NULL;

        /* Reset the parser state */
        gupnp_didl_lite_writer_reset (server->priv->didl_writer);

        return result;
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
        char *result;
        guint num_returned;

        server = GUPNP_MEDIA_SERVER (user_data);

        /* Handle incoming arguments */
        gupnp_service_action_get (action,
                                  "ObjectID",
                                        G_TYPE_STRING,
                                        &object_id,
                                  "BrowseFlag",
                                        G_TYPE_STRING,
                                        &browse_flag,
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
                result = get_metadata (server, object_id, &num_returned);

                if (result == NULL) {
                        gupnp_service_action_return_error
                                (action, 701, "No such object");

                        goto OUT;
                }
        } else {
                /* We only have a root object */
                if (strcmp (object_id, "0")) {
                        gupnp_service_action_return_error
                                (action, 701, "No such object");

                        goto OUT;
                }

                result = browse_direct_children (server, &num_returned);
        }

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
                                        num_returned,
                                  "UpdateID",
                                        G_TYPE_UINT,
                                        server->priv->system_update_id,
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

