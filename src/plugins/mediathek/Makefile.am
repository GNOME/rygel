plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-mediathek.la

AM_CFLAGS = \
	$(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(LIBDBUS_GLIB_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGCONF_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src/rygel \
	-DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-mediathek-asx-playlist.c \
		rygel-mediathek-plugin.c \
		rygel-mediathek-video-item.c \
		rygel-mediathek-root-container.c \
		rygel-mediathek-rss-container.c

$(BUILT_SOURCES) : rygel-mediathek.stamp

librygel_mediathek_la_SOURCES = \
	rygel-mediathek-asx-playlist.c \
	rygel-mediathek-asx-playlist.vala \
	rygel-mediathek-plugin.c \
	rygel-mediathek-plugin.vala \
	rygel-mediathek-video-item.c \
	rygel-mediathek-video-item.vala \
	rygel-mediathek-root-container.c \
	rygel-mediathek-root-container.vala \
	rygel-mediathek-rss-container.c \
	rygel-mediathek-rss-container.vala 


rygel-mediathek.stamp: $(filter %.vala,$(librygel_mediathek_la_SOURCES))
	$(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 \
	--pkg cstuff \
	--pkg gupnp-1.0 \
	--pkg gupnp-av-1.0 \
	--pkg libsoup-2.4 \
	--pkg gee-1.0 \
	--pkg libxml-2.0 \
	--pkg gconf-2.0 \
	$^
	touch $@

librygel_mediathek_la_LIBADD = \
	$(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBDBUS_GLIB_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGCONF_LIBS) \
	$(GEE_LIBS)

librygel_mediathek_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-mediathek.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-mediathek.stamp
