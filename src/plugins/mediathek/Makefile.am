include ../../../common.am

plugin_LTLIBRARIES = librygel-mediathek.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Mediathek"'

librygel_mediathek_la_SOURCES = \
	rygel-mediathek-asx-playlist-parser.vala \
	rygel-mediathek-mov-playlist-parser.vala \
	rygel-mediathek-plugin.vala \
	rygel-mediathek-playlist-parser.vala \
	rygel-mediathek-video-item-factory.vala \
	rygel-mediathek-root-container.vala \
	rygel-mediathek-rss-container.vala \
	rygel-mediathek-soup-utils.vala

librygel_mediathek_la_VALAFLAGS = $(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)
librygel_mediathek_la_LIBADD = $(RYGEL_COMMON_SERVER_LIBS) $(LIBGIO_LIBS) $(LIBSOUP_LIBS)
librygel_mediathek_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
