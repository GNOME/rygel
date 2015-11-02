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

