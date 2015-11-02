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

#include "example-server-plugin.h"
#include "example-root-container.h"

#define RYGEL_EXAMPLE_SERVER_PLUGIN_NAME "ExampleServerPluginC"

enum  {
  RYGEL_EXAMPLE_SERVER_PLUGIN_DUMMY_PROPERTY
};

#define RYGEL_EXAMPLE_SERVER_PLUGIN_TITLE "Example Server Plugin C"
#define RYGEL_EXAMPLE_SERVER_PLUGIN_DESCRIPTION "An example Rygel server plugin implemented in C."

G_DEFINE_TYPE (RygelExampleServerPlugin, rygel_example_server_plugin, RYGEL_TYPE_MEDIA_SERVER_PLUGIN)

void
module_init (RygelPluginLoader* loader) {
  RygelExampleServerPlugin* plugin;

  g_return_if_fail (loader != NULL);

  if (rygel_plugin_loader_plugin_disabled (loader, RYGEL_EXAMPLE_SERVER_PLUGIN_NAME)) {
    g_message ("Plugin '%s' disabled by user. Ignoring.",
      RYGEL_EXAMPLE_SERVER_PLUGIN_NAME);
    return;
  }

  plugin = rygel_example_server_plugin_new ();
  rygel_plugin_loader_add_plugin (loader, RYGEL_PLUGIN (plugin));
  g_object_unref (plugin);
}


static RygelExampleServerPlugin*
rygel_example_server_plugin_construct (GType object_type) {
  RygelExampleServerPlugin *self;
  RygelExampleRootContainer *root_container;

  root_container =
    rygel_example_root_container_new (RYGEL_EXAMPLE_SERVER_PLUGIN_TITLE);
  self = (RygelExampleServerPlugin*) rygel_media_server_plugin_construct (object_type,
    (RygelMediaContainer*) root_container, RYGEL_EXAMPLE_SERVER_PLUGIN_NAME,
    RYGEL_EXAMPLE_SERVER_PLUGIN_DESCRIPTION, RYGEL_PLUGIN_CAPABILITIES_NONE);
  g_object_unref (root_container);

  return self;
}


RygelExampleServerPlugin*
rygel_example_server_plugin_new (void) {
  return rygel_example_server_plugin_construct (RYGEL_EXAMPLE_TYPE_SERVER_PLUGIN);
}


static void
rygel_example_server_plugin_class_init (RygelExampleServerPluginClass *klass) {
}


static void
rygel_example_server_plugin_init (RygelExampleServerPlugin *self) {
}


