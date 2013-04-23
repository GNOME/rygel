include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-renderer-plugin-c.la
plugin_DATA = example-renderer-c.plugin

librygel_example_renderer_plugin_c_la_SOURCES = \
	example-renderer-plugin.h \
	example-renderer-plugin.c \
	example-player.h \
	example-player.c

# TODO: Do we need all these?
librygel_example_renderer_plugin_c_la_CFLAGS = \
	$(EXAMPLE_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_CFLAGS) \
	-DG_LOG_DOMAIN='"ExampleRendererPluginC"'

librygel_example_renderer_plugin_c_la_LIBADD = \
	$(EXAMPLE_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_LIBS)
	
librygel_example_renderer_plugin_c_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = example-renderer-c.plugin.in
