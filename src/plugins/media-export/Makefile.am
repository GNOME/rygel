plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-media-export.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(LIBDBUS_GLIB_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGCONF_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-media-export-root-container.c \
		rygel-media-export-container.c \
		rygel-media-export-directory-search-result.c \
		rygel-media-export-plugin.c

$(BUILT_SOURCES) : rygel-media-media-export.stamp

librygel_media_media_export_la_SOURCES = \
	rygel-media-export-plugin.c \
	rygel-media-export-plugin.vala \
	rygel-media-export-root-container.c \
	rygel-media-export-root-container.vala \
	rygel-media-export-container.c \
	rygel-media-export-container.vala \
	rygel-media-export-directory-search-result.c \
	rygel-media-export-directory-search-result.vala

rygel-media-media-export.stamp: $(filter %.vala,$(librygel_media_media_export_la_SOURCES))
	$(VALAC) -g -C --vapidir=$(top_srcdir)/src/rygel \
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

librygel_media_media_export_la_LIBADD = \
	$(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBDBUS_GLIB_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGCONF_LIBS) \
	$(GEE_LIBS)
librygel_media_media_export_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-media-media-export.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-media-media-export.stamp
