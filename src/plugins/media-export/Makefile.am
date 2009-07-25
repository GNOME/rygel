plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-export.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(LIBDBUS_GLIB_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

$(librygel_media_export_la_SOURCES) : rygel-media-export.stamp

librygel_media_export_la_VALASOURCES = \
	rygel-media-export-plugin.vala \
	rygel-media-export-root-container.vala \
	rygel-media-export-harvester.vala \
	rygel-media-export-item.vala
librygel_media_export_la_SOURCES = \
	$(librygel_media_export_la_VALASOURCES:.vala=.c)

rygel-media-export.stamp: $(librygel_media_export_la_VALASOURCES)
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

librygel_media_export_la_LIBADD = \
	$(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBDBUS_GLIB_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(GEE_LIBS)
librygel_media_export_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = rygel-media-export.stamp
MAINTAINERCLEANFILES = Makefile.in $(librygel_media_export_la_SOURCES)
EXTRA_DIST = $(librygel_media_export_la_VALASOURCES) rygel-media-export.stamp
