include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-renderer-plugin-vala.la

AM_CFLAGS += -DG_LOG_DOMAIN='"ExampleRendererPluginVala"'

librygel_example_renderer_plugin_vala_la_SOURCES = \
	example-renderer-plugin-vala.vala \
	example-player-vala.vala

librygel_example_renderer_plugin_vala_la_VALAFLAGS = \
	--pkg gstreamer-0.10 \
	$(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)

librygel_example_renderer_plugin_vala_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_RENDERER_LIBS)
	
librygel_example_renderer_plugin_vala_la_LDFLAGS = \
  $(RYGEL_PLUGIN_LINKER_FLAGS)
