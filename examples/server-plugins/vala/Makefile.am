include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-server-plugin-vala.la
plugin_DATA = example-server-vala.plugin

# Note that we must have these Vala prefixes on the
# class names (and therefore on the file names)
# to avoid conflicts with other plugins.
librygel_example_server_plugin_vala_la_SOURCES = \
	example-server-plugin-vala.vala \
	example-root-container-vala.vala

librygel_example_server_plugin_vala_la_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_example_server_plugin_vala_la_CFLAGS = \
	$(EXAMPLE_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"ExampleServerPluginVala"'

librygel_example_server_plugin_vala_la_LIBADD = \
	$(EXAMPLE_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
	
librygel_example_server_plugin_vala_la_LDFLAGS = \
  $(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = example-server-vala.plugin.in
