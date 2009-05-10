plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-folder.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	$(LIBGUPNP_AV_CFLAGS) \
	$(LIBDBUS_GLIB_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGCONF_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-folder-root-container.c \
		rygel-folder-container.c \
		rygel-folder-directory-search-result.c \
		rygel-folder-plugin.c

$(BUILT_SOURCES) : rygel-media-folder.stamp

librygel_media_folder_la_SOURCES = \
	rygel-folder-plugin.c \
	rygel-folder-plugin.vala \
	rygel-folder-root-container.c \
	rygel-folder-root-container.vala \
	rygel-folder-container.c \
	rygel-folder-container.vala \
	rygel-folder-directory-search-result.c \
	rygel-folder-directory-search-result.vala

rygel-media-folder.stamp: $(filter %.vala,$(librygel_media_folder_la_SOURCES))
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

librygel_media_folder_la_LIBADD = \
	$(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBDBUS_GLIB_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGCONF_LIBS) \
	$(GEE_LIBS)
librygel_media_folder_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-media-folder.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-media-folder.stamp
