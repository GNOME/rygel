/* Copyright (C) 2012 Intel Corporation
 *
 * Permission to use, copy, modify, distribute, and sell this example
 * for any purpose is hereby granted without fee.
 * It is provided "as is" without express or implied warranty.
 */

#ifndef __RYGEL_EXAMPLE_SERVER_PLUGIN_H__
#define __RYGEL_EXAMPLE_SERVER_PLUGIN_H__

#include <glib.h>
#include <glib-object.h>
#include <rygel-server.h>

G_BEGIN_DECLS

#define RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN (rygel_example_server_plugin_get_type ())
#define RYGEL_EXAMPLE_SERVER_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN, RygelExampleServerPlugin))
#define RYGEL_EXAMPLE_SERVER_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN, RygelExampleServerPluginClass))
#define RYGEL_EXAMPLE_IS_SERVER_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN))
#define RYGEL_EXAMPLE_IS_SERVER_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN))
#define RYGEL_EXAMPLE_SERVER_PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN, RygelExampleServerPluginClass))

typedef struct _RygelExampleServerPlugin RygelExampleServerPlugin;
typedef struct _RygelExampleServerPluginClass RygelExampleServerPluginClass;
typedef struct _RygelExampleServerPluginPrivate RygelExampleServerPluginPrivate;

struct _RygelExampleServerPlugin {
  RygelMediaServerPlugin parent_instance;
  RygelExampleServerPluginPrivate * priv;
};

struct _RygelExampleServerPluginClass {
  RygelMediaServerPluginClass parent_class;
};

GType rygel_example_server_plugin_get_type (void) G_GNUC_CONST;

RygelExampleServerPlugin* rygel_example_server_plugin_new (void);

void module_init (RygelPluginLoader* loader);

G_END_DECLS

#endif /* __RYGEL_EXAMPLE_SERVER_PLUGIN_H__ */

