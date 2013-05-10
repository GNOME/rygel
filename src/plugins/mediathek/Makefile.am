include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-mediathek.la
plugin_DATA = mediathek.plugin

librygel_mediathek_la_SOURCES = \
	rygel-mediathek-asx-playlist-parser.vala \
	rygel-mediathek-mov-playlist-parser.vala \
	rygel-mediathek-plugin.vala \
	rygel-mediathek-playlist-parser.vala \
	rygel-mediathek-video-item-factory.vala \
	rygel-mediathek-root-container.vala \
	rygel-mediathek-rss-container.vala \
	rygel-mediathek-soup-utils.vala

librygel_mediathek_la_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_mediathek_la_CFLAGS = \
	$(RYGEL_PLUGIN_MEDIATHEK_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	$(RYGEL_COMMON_DEFINES_CFLAGS) \
	-DG_LOG_DOMAIN='"Mediathek"'
librygel_mediathek_la_LIBADD = \
	$(RYGEL_PLUGIN_MEDIATHEK_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
librygel_mediathek_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = mediathek.plugin.in
