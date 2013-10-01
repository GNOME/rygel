include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-playbin.la
plugin_DATA = playbin.plugin

librygel_playbin_la_SOURCES = rygel-playbin-module.vala rygel-playbin-plugin.vala
librygel_playbin_la_VALAFLAGS = \
	--pkg rygel-renderer-gst-2.0 \
	--vapidir $(top_srcdir)/src/librygel-renderer-gst \
	--enable-experimental \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_playbin_la_CFLAGS = \
	$(RYGEL_PLUGIN_PLAYBIN_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_CFLAGS) \
	-DG_LOG_DOMAIN='"Playbin"'
librygel_playbin_la_LIBADD = \
	$(RYGEL_PLUGIN_PLAYBIN_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_LIBS)
librygel_playbin_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = playbin.plugin.in
