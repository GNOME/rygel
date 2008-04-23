/*
 * Copyright (C) 2007 OpenedHand Ltd.
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali <zeenix@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <string.h>
#include "gupnp-media-server.h"

G_DEFINE_TYPE (GUPnPMediaServer,
               gupnp_media_server,
               GUPNP_TYPE_ROOT_DEVICE);

struct _GUPnPMediaServerPrivate {
        GUPnPRootDevice *root_device;
};

static void
gupnp_media_server_dispose (GObject *object)
{
        GUPnPMediaServer *server;
        GObjectClass *object_class;

        server = GUPNP_DEVICE (object);

        if (server->priv->root_device) {
                g_object_unref (server->priv->root_device);
                server->priv->root_device = NULL;
        }

        /* Call super */
        object_class = G_OBJECT_CLASS (gupnp_media_server_parent_class);
        object_class->dispose (object);
}

static void
gupnp_media_server_init (GUPnPMediaServer *server)
{
        server->priv = G_TYPE_INSTANCE_GET_PRIVATE (server,
                                                    GUPNP_TYPE_DEVICE,
                                                    GUPnPMediaServerPrivate);
}

static void
gupnp_media_server_class_init (GUPnPMediaServerClass *klass)
{
        GObjectClass *object_class;
        GUPnPMediaServerInfoClass *info_class;

        object_class = G_OBJECT_CLASS (klass);

        object_class->dispose = gupnp_media_server_dispose;

        info_class = GUPNP_DEVICE_INFO_CLASS (klass);

        g_type_class_add_private (klass, sizeof (GUPnPMediaServerPrivate));
}

