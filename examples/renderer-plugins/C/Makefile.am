include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-renderer-plugin-c.la

AM_CFLAGS += -DG_LOG_DOMAIN='"ExampleRendererPluginC"'

librygel_example_renderer_plugin_c_la_SOURCES = \
	example-renderer-plugin.h \
	example-renderer-plugin.h \
	example-player.h \
	example-player.c

# You would ususally just use pkg-config:
librygel_core_includes = -I$(top_builddir)/src/librygel-core $(if $(srcdir:.=),-I$(top_srcdir)/src/librygel-core)
librygel_renderer_includes = -I$(top_builddir)/src/librygel-renderer $(if $(srcdir:.=),-I$(top_srcdir)/src/librygel-renderer)

# TODO: Do we need all these?
librygel_example_renderer_plugin_c_la_CFLAGS = \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(GEE_CFLAGS) \
	$(librygel_core_includes) \
	$(librygel_renderer_includes)

librygel_example_renderer_plugin_c_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_RENDERER_LIBS)
	
librygel_example_renderer_plugin_c_la_LDFLAGS = \
  $(RYGEL_PLUGIN_LINKER_FLAGS)

