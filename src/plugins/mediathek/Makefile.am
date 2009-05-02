plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-mediathek.la

AM_CFLAGS = \
	$(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(LIBDBUS_GLIB_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGCONF_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src/rygel \
	-DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-media-mediathek.stamp \
				rygel-mediathek-asx.c \
				rygel-mediathek-plugin.c \
				rygel-mediathek-item.c \
				rygel-mediathek-container-root.c \
				rygel-mediathek-container-rss.c

librygel_media_mediathek_la_SOURCES = \
	rygel-mediathek-asx.c \
	rygel-mediathek-asx.vala \
	rygel-mediathek-plugin.c \
	rygel-mediathek-plugin.vala \
	rygel-mediathek-item.c \
	rygel-mediathek-item.vala \
	rygel-mediathek-container-root.c \
	rygel-mediathek-container-root.vala \
	rygel-mediathek-container-rss.c \
	rygel-mediathek-container-rss.vala 


rygel-media-mediathek.stamp: $(filter %.vala,$(librygel_media_mediathek_la_SOURCES))
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

librygel_media_mediathek_la_LIBADD = \
	$(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBDBUS_GLIB_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGCONF_LIBS) \
	$(GEE_LIBS)

librygel_media_mediathek_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
