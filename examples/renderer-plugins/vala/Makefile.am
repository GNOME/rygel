include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-renderer-plugin-vala.la
plugin_DATA = example-renderer-vala.plugin

librygel_example_renderer_plugin_vala_la_SOURCES = \
	example-renderer-plugin-vala.vala \
	example-player-vala.vala

librygel_example_renderer_plugin_vala_la_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_example_renderer_plugin_vala_la_CFLAGS = \
	$(EXAMPLE_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_CFLAGS) \
	-DG_LOG_DOMAIN='"ExampleRendererPluginVala"'
librygel_example_renderer_plugin_vala_la_LIBADD = \
	$(EXAMPLE_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_LIBS)
	
librygel_example_renderer_plugin_vala_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = example-renderer-vala.plugin.in
