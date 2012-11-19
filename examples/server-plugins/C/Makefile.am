include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-server-plugin-c.la

AM_CFLAGS += -DG_LOG_DOMAIN='"ExampleServerPluginC"'

librygel_example_server_plugin_c_la_SOURCES = \
	example-server-plugin.h \
	example-server-plugin.c \
	example-root-container.h \
	example-root-container.c

# You would ususally just use pkg-config:
librygel_core_includes = -I$(top_builddir)/src/librygel-core $(if $(srcdir:.=),-I$(top_srcdir)/src/librygel-core)
librygel_server_includes = -I$(top_builddir)/src/librygel-server $(if $(srcdir:.=),-I$(top_srcdir)/src/librygel-server)

librygel_example_server_plugin_c_la_CFLAGS = \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(GEE_CFLAGS) \
	$(librygel_core_includes) \
	$(librygel_server_includes)

librygel_example_server_plugin_c_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_SERVER_LIBS)
	
librygel_example_server_plugin_c_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)
