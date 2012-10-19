include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-example-server-plugin.la

AM_CFLAGS += -DG_LOG_DOMAIN='"ExampleServerPlugin"'

librygel_example_server_plugin_la_SOURCES = \
	example-server-plugin.vala \
	example-root-container.vala

librygel_example_server_plugin_la_VALAFLAGS = \
	--pkg gstreamer-0.10 \
	$(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)

librygel_example_server_plugin_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_SERVER_LIBS)
	
librygel_example_server_plugin_la_LDFLAGS = \
  $(RYGEL_PLUGIN_LINKER_FLAGS)
