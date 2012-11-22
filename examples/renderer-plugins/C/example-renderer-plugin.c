/*
 * Copyright (C) 2012 Intel Corporation
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include "example-renderer-plugin.h"
#include "example-player.h"

#define RYGEL_EXAMPLE_RENDERER_PLUGIN_NAME "ExampleRenderPluginC"

enum  {
  RYGEL_EXAMPLE_RENDERER_PLUGIN_DUMMY_PROPERTY
};

#define RYGEL_EXAMPLE_RENDERER_PLUGIN_TITLE "Example Render Plugin C"
#define RYGEL_EXAMPLE_RENDERER_PLUGIN_DESCRIPTION "An example Rygel renderer plugin implemented in C."

G_DEFINE_TYPE (RygelExampleRenderPlugin, rygel_example_renderer_plugin, RYGEL_TYPE_MEDIA_RENDERER_PLUGIN)

void
module_init (RygelPluginLoader* loader) {
  RygelExampleRenderPlugin* plugin;

  g_return_if_fail (loader != NULL);

  if (rygel_plugin_loader_plugin_disabled (loader, RYGEL_EXAMPLE_RENDERER_PLUGIN_NAME)) {
    g_message ("Plugin '%s' disabled by user. Ignoring.",
      RYGEL_EXAMPLE_RENDERER_PLUGIN_NAME);
    return;
  }

  plugin = rygel_example_renderer_plugin_new ();
  rygel_plugin_loader_add_plugin (loader, RYGEL_PLUGIN (plugin));
  g_object_unref (plugin);
}


RygelExampleRenderPlugin*
rygel_example_renderer_plugin_construct (GType object_type) {
  RygelExampleRenderPlugin *self;
  RygelExampleRootContainer *root_container;

  root_container =
    rygel_example_root_container_new (RYGEL_EXAMPLE_RENDERER_PLUGIN_TITLE);
  self = (RygelExampleRenderPlugin*) rygel_media_renderer_plugin_construct (object_type,
    (RygelMediaContainer*) root_container, RYGEL_EXAMPLE_RENDERER_PLUGIN_NAME,
    RYGEL_EXAMPLE_RENDERER_PLUGIN_DESCRIPTION, RYGEL_PLUGIN_CAPABILITIES_NONE);
  g_object_unref (root_container);

  return self;
}


RygelExampleRenderPlugin*
rygel_example_renderer_plugin_new (void) {
  return rygel_example_renderer_plugin_construct (RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN);
}


static void
rygel_example_renderer_plugin_class_init (RygelExampleRenderPluginClass *klass) {
}


static void
rygel_example_renderer_plugin_init (RygelExampleRenderPlugin *self) {
}


