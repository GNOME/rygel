include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-mpris.la
plugin_DATA = mpris.plugin

librygel_mpris_la_SOURCES = \
	rygel-mpris-player.vala \
	rygel-mpris-plugin.vala \
	rygel-mpris-plugin-factory.vala \
	rygel-mpris-interfaces.vala

librygel_mpris_la_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_mpris_la_CFLAGS = \
	$(RYGEL_PLUGIN_MPRIS_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_CFLAGS) \
	-DG_LOG_DOMAIN='"MPRIS"'
librygel_mpris_la_LIBADD = \
	$(RYGEL_PLUGIN_MPRIS_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_LIBS)
librygel_mpris_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = mpris.plugin.in
