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
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

#include <string.h>
#include <libgupnp/gupnp.h>
#include <libgupnp-av/gupnp-av.h>

#include "gupnp-media-receiver-registrar.h"
#include "gupnp-media-tracker.h"

G_DEFINE_TYPE (GUPnPMediaReceiverRegistrar,
               gupnp_media_receiver_registrar,
               GUPNP_TYPE_SERVICE);

static GObject *
gupnp_media_receiver_registrar_constructor
                        (GType                  type,
                         guint                  n_construct_params,
                         GObjectConstructParam *construct_params)
{
        GObject *object;
        GObjectClass *object_class;
        GUPnPService *service;
        GError *error;

        object_class =
                G_OBJECT_CLASS (gupnp_media_receiver_registrar_parent_class);
        object = object_class->constructor (type,
                                            n_construct_params,
                                            construct_params);

        if (object == NULL)
                return NULL;

        service = GUPNP_SERVICE (object);

        error = NULL;
        gupnp_service_signals_autoconnect (service,
                                           NULL,
                                           &error);
        if (error) {
                g_warning ("Error autoconnecting signals: %s",
                           error->message);
                g_error_free (error);
        }

        return object;
}

static void
gupnp_media_receiver_registrar_init (GUPnPMediaReceiverRegistrar *registrar)
{
}

static void
gupnp_media_receiver_registrar_class_init
                (GUPnPMediaReceiverRegistrarClass *klass)
{
        GObjectClass *object_class;

        object_class = G_OBJECT_CLASS (klass);

        object_class->constructor = gupnp_media_receiver_registrar_constructor;
}

/* IsAuthorized action implementation (fake) */
void
is_authorized_cb (GUPnPMediaReceiverRegistrar *registrar,
                  GUPnPServiceAction          *action,
                  gpointer                     user_data)
{
        /* Set action return arguments */
        gupnp_service_action_set (action,
                                  "Result",
                                  G_TYPE_INT,
                                  1,
                                  NULL);

        gupnp_service_action_return (action);
}

/* RegisterDevice action implementation (fake) */
void
register_device_cb (GUPnPMediaReceiverRegistrar *registrar,
                    GUPnPServiceAction          *action,
                    gpointer                     user_data)
{
        /* Set action return arguments */
        gupnp_service_action_set (action,
                                  "RegistrationRespMsg",
                                  GUPNP_TYPE_BIN_BASE64,
                                  "WhatisSupposedToBeHere",
                                  NULL);

        gupnp_service_action_return (action);
}

/* IsValidated action implementation (fake) */
void
is_validated_cb (GUPnPMediaReceiverRegistrar *registrar,
                 GUPnPServiceAction          *action,
                 gpointer                     user_data)
{
        /* Set action return arguments */
        gupnp_service_action_set (action,
                                  "Result",
                                  G_TYPE_INT,
                                  1,
                                  NULL);

        gupnp_service_action_return (action);
}

