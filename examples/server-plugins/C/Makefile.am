include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-server-plugin-c.la
plugin_DATA = example-server-c.plugin

librygel_example_server_plugin_c_la_SOURCES = \
	example-server-plugin.h \
	example-server-plugin.c \
	example-root-container.h \
	example-root-container.c

librygel_example_server_plugin_c_la_CFLAGS = \
	$(EXAMPLE_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"ExampleServerPluginC"'

librygel_example_server_plugin_c_la_LIBADD = \
	$(EXAMPLE_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS) \
	$(RYGEL_COMMON_SERVER_LIBS)
	
librygel_example_server_plugin_c_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = example-server-c.plugin.in
