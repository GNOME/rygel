/* Copyright (C) 2012 Intel Corporation
 *
 * Permission to use, copy, modify, distribute, and sell this example
 * for any purpose is hereby granted without fee.
 * It is provided "as is" without express or implied warranty.
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
