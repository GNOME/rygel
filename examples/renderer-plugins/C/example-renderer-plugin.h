/* Copyright (C) 2012 Intel Corporation
 *
 * Permission to use, copy, modify, distribute, and sell this example
 * for any purpose is hereby granted without fee.
 * It is provided "as is" without express or implied warranty.
 */

#ifndef __RYGEL_EXAMPLE_RENDERER_PLUGIN_H__
#define __RYGEL_EXAMPLE_RENDERER_PLUGIN_H__

#include <glib.h>
#include <glib-object.h>
#include <rygel-renderer.h>

G_BEGIN_DECLS

#define RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN (rygel_example_renderer_plugin_get_type ())
#define RYGEL_EXAMPLE_RENDERER_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN, RygelExampleRendererPlugin))
#define RYGEL_EXAMPLE_RENDERER_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN, RygelExampleRendererPluginClass))
#define RYGEL_EXAMPLE_IS_RENDERER_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN))
#define RYGEL_EXAMPLE_IS_RENDERER_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN))
#define RYGEL_EXAMPLE_RENDERER_PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), RYGEL_EXAMPLE_TYPE_RENDERER_PLUGIN, RygelExampleRendererPluginClass))

typedef struct _RygelExampleRendererPlugin RygelExampleRendererPlugin;
typedef struct _RygelExampleRendererPluginClass RygelExampleRendererPluginClass;
typedef struct _RygelExampleRendererPluginPrivate RygelExampleRendererPluginPrivate;

struct _RygelExampleRendererPlugin {
  RygelMediaRendererPlugin parent_instance;
  RygelExampleRendererPluginPrivate * priv;
};

struct _RygelExampleRendererPluginClass {
  RygelMediaRendererPluginClass parent_class;
};

GType rygel_example_renderer_plugin_get_type (void) G_GNUC_CONST;

RygelExampleRendererPlugin* rygel_example_renderer_plugin_new (void);

void module_init (RygelPluginLoader* loader);

G_END_DECLS

#endif /* __RYGEL_EXAMPLE_RENDERER_PLUGIN_H__ */

