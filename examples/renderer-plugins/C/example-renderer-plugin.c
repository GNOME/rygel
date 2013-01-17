/* Copyright (C) 2012 Intel Corporation
 *
 * Permission to use, copy, modify, distribute, and sell this example
 * for any purpose is hereby granted without fee.
 * It is provided "as is" without express or implied warranty.
 */

#include "example-renderer-plugin.h"
#include "example-player.h"

#define RYGEL_EXAMPLE_RENDERER_PLUGIN_NAME "ExampleRendererPluginC"

enum  {
  RYGEL_EXAMPLE_RENDERER_PLUGIN_DUMMY_PROPERTY
};

#define RYGEL_EXAMPLE_RENDERER_PLUGIN_TITLE "Example Render Plugin C"
#define RYGEL_EXAMPLE_RENDERER_PLUGIN_DESCRIPTION "An example Rygel renderer plugin implemented in C."

G_DEFINE_TYPE (RygelExampleRendererPlugin, rygel_example_renderer_plugin, RYGEL_TYPE_MEDIA_RENDERER_PLUGIN)

static RygelExamplePlayer *player;

void
module_init (RygelPluginLoader* loader) {
  RygelExampleRendererPlugin* plugin;

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


static RygelExampleRendererPlugin*
rygel_example_renderer_plugin_construct (GType object_type) {
  RygelExampleRendererPlugin *self;

  self = (RygelExampleRendererPlugin*) rygel_media_renderer_plugin_construct (object_type,
    RYGEL_EXAMPLE_RENDERER_PLUGIN_NAME, NULL, RYGEL_EXAMPLE_RENDERER_PLUGIN_DESCRIPTION,
    RYGEL_PLUGIN_CAPABILITIES_NONE);

  return self;
}


RygelExampleRendererPlugin*
rygel_example_renderer_plugin_new (void) {
  return rygel_example_renderer_plugin_construct (RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN);
}


static RygelMediaPlayer *
rygel_example_renderer_plugin_get_player (RygelMediaRendererPlugin* plugin)
{
    if (player == NULL) {
        player = rygel_example_player_new ();
    }

    return RYGEL_EXAMPLE_PLAYER (g_object_ref (player));
}

static void
rygel_example_renderer_plugin_class_init (RygelExampleRendererPluginClass *klass) {
    RygelMediaRendererPluginClass *plugin_class;

    plugin_class = RYGEL_EXAMPLE_RENDERER_PLUGIN_CLASS (klass);
    plugin_class->get_player = rygel_example_renderer_plugin_get_player;
}


static void
rygel_example_renderer_plugin_init (RygelExampleRendererPlugin *self) {
}


