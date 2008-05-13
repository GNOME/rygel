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
#include "gupnp-content-directory.h"
#include "gupnp-media-receiver-registrar.h"

#define CONTENT_DIR "urn:schemas-upnp-org:service:ContentDirectory"
#define CONTENT_DIR_V1 CONTENT_DIR ":1"
#define CONTENT_DIR_V2 CONTENT_DIR ":2"
#define MEDIA_RECEIVER_REGISTRAR "urn:microsoft.com:service" \
                                 ":X_MS_MediaReceiverRegistrar"
#define MEDIA_RECEIVER_REGISTRAR_V1 MEDIA_RECEIVER_REGISTRAR ":1"
#define MEDIA_RECEIVER_REGISTRAR_V2 MEDIA_RECEIVER_REGISTRAR ":2"

G_DEFINE_TYPE (GUPnPMediaServer,
               gupnp_media_server,
               GUPNP_TYPE_ROOT_DEVICE);

struct _GUPnPMediaServerPrivate {
        GUPnPService *content_dir;      /* ContentDirectory */
        GUPnPService *msr;              /* MS MediaReceiverRegistrar */
};

/* GObject stuff */
static void
gupnp_media_server_dispose (GObject *object)
{
        GUPnPMediaServer *server;
        GObjectClass *object_class;

        server = GUPNP_MEDIA_SERVER (object);

        /* Free GUPnP resources */
        if (server->priv->content_dir) {
                g_object_unref (server->priv->content_dir);
                server->priv->content_dir = NULL;
        }
        if (server->priv->msr) {
                g_object_unref (server->priv->msr);
                server->priv->msr = NULL;
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
        GUPnPDeviceInfo  *info;
        GUPnPServiceInfo *service;
        GUPnPResourceFactory *factory;

        object_class = G_OBJECT_CLASS (gupnp_media_server_parent_class);
        object = object_class->constructor (type,
                                            n_construct_params,
                                            construct_params);

        if (object == NULL)
                return NULL;

        server = GUPNP_MEDIA_SERVER (object);
        info = GUPNP_DEVICE_INFO (server);

        factory = gupnp_device_info_get_resource_factory (info);

        /* Register GUPnPContentDirectory and GUPnPMediaReceiverRegistrar */
        gupnp_resource_factory_register_resource_type
                                (factory,
                                 CONTENT_DIR_V1,
                                 GUPNP_TYPE_CONTENT_DIRECTORY);
        gupnp_resource_factory_register_resource_type
                                (factory,
                                 CONTENT_DIR_V2,
                                 GUPNP_TYPE_CONTENT_DIRECTORY);

        gupnp_resource_factory_register_resource_type
                                (factory,
                                 MEDIA_RECEIVER_REGISTRAR_V1,
                                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR);
        gupnp_resource_factory_register_resource_type
                                (factory,
                                 MEDIA_RECEIVER_REGISTRAR_V2,
                                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR);

        /* Now create the sevice objects */
        service = gupnp_device_info_get_service (info, CONTENT_DIR);
        server->priv->content_dir = GUPNP_SERVICE (service);

        service =
                gupnp_device_info_get_service (info, MEDIA_RECEIVER_REGISTRAR);
        server->priv->msr = GUPNP_SERVICE (service);

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

