/*
 * Copyright (C) 2012 Intel Corporation
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef __RYGEL_EXAMPLE_ROOT_CONTAINER_H__
#define __RYGEL_EXAMPLE_ROOT_CONTAINER_H__

#include <glib.h>
#include <glib-object.h>
#include <rygel-server.h>

G_BEGIN_DECLS

#define RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER (rygel_example_root_container_get_type ())
#define RYGEL_EXAMPLE_ROOT_CONTAINER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER, RygelExampleRootContainer))
#define RYGEL_EXAMPLE_ROOT_CONTAINER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER, RygelExampleRootContainerClass))
#define RYGEL_EXAMPLE_IS_ROOT_CONTAINER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER))
#define RYGEL_EXAMPLE_IS_ROOT_CONTAINER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER))
#define RYGEL_EXAMPLE_ROOT_CONTAINER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER, RygelExampleRootContainerClass))

typedef struct _RygelExampleRootContainer RygelExampleRootContainer;
typedef struct _RygelExampleRootContainerClass RygelExampleRootContainerClass;

typedef struct _RygelExampleRootContainerPrivate RygelExampleRootContainerPrivate;

struct _RygelExampleRootContainer {
  RygelSimpleContainer parent_instance;
  RygelExampleRootContainerPrivate * priv;
};

struct _RygelExampleRootContainerClass {
  RygelSimpleContainerClass parent_class;
};

RygelExampleRootContainer* rygel_example_root_container_new (const gchar* title);

GType rygel_example_root_container_get_type (void);

G_END_DECLS

#endif /* __RYGEL_EXAMPLE_ROOT_CONTAINER_H__ */
