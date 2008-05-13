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

#ifndef __GUPNP_MEDIA_RECEIVER_REGISTRAR_H__
#define __GUPNP_MEDIA_RECEIVER_REGISTRAR_H__

#include <libgupnp/gupnp.h>

G_BEGIN_DECLS

GType
gupnp_media_receiver_registrar_get_type (void) G_GNUC_CONST;

#define GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR \
                (gupnp_media_receiver_registrar_get_type ())
#define GUPNP_MEDIA_RECEIVER_REGISTRAR(obj) \
                (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR, \
                 GUPnPMediaReceiverRegistrar))
#define GUPNP_MEDIA_RECEIVER_REGISTRAR_CLASS(obj) \
                (G_TYPE_CHECK_CLASS_CAST ((obj), \
                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR, \
                 GUPnPMediaReceiverRegistrarClass))
#define GUPNP_IS_MEDIA_RECEIVER_REGISTRAR(obj) \
                (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR))
#define GUPNP_IS_MEDIA_RECEIVER_REGISTRAR_CLASS(obj) \
                (G_TYPE_CHECK_CLASS_TYPE ((obj), \
                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR))
#define GUPNP_MEDIA_RECEIVER_REGISTRAR_GET_CLASS(obj) \
                (G_TYPE_INSTANCE_GET_CLASS ((obj), \
                 GUPNP_TYPE_MEDIA_RECEIVER_REGISTRAR, \
                 GUPnPMediaReceiverRegistrarClass))

typedef struct _GUPnPMediaReceiverRegistrarPrivate GUPnPMediaReceiverRegistrarPrivate;

typedef struct {
        GUPnPService parent;

        /* future padding */
        gpointer _gupnp_reserved;
} GUPnPMediaReceiverRegistrar;

typedef struct {
        GUPnPServiceClass parent_class;

        /* future padding */
        void (* _gupnp_reserved1) (void);
        void (* _gupnp_reserved2) (void);
        void (* _gupnp_reserved3) (void);
        void (* _gupnp_reserved4) (void);
} GUPnPMediaReceiverRegistrarClass;

G_END_DECLS

#endif /* __GUPNP_MEDIA_RECEIVER_REGISTRAR_H__ */

