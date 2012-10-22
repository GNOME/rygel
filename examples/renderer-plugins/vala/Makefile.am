include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-renderer-plugin.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Example"'

librygel_example_renderer_plugin_la_SOURCES = \
	example-renderer-plugin.vala \
	example-player.vala

librygel_example_renderer_plugin_la_VALAFLAGS = \
	--pkg gstreamer-0.10 \
	$(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)

librygel_example_renderer_plugin_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_RENDERER_LIBS)
	
librygel_example_renderer_plugin_la_LDFLAGS = \
  $(RYGEL_PLUGIN_LINKER_FLAGS)
