if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-mediathek.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GEE_CFLAGS) \
            $(UUID_CFLAGS) \
	    -I$(top_srcdir)/src/rygel \
	    -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

librygel_mediathek_la_SOURCES = rygel-mediathek-asx-playlist.vala \
				rygel-mediathek-plugin.vala \
				rygel-mediathek-video-item.vala \
				rygel-mediathek-root-container.vala \
				rygel-mediathek-rss-container.vala

librygel_mediathek_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
				  --pkg rygel-1.0 \
				  --pkg cstuff \
				  --pkg gupnp-1.0 \
				  --pkg gupnp-av-1.0 \
				  --pkg libsoup-2.4 \
				  --pkg gee-1.0 \
				  --pkg libxml-2.0 \
				  --pkg gconf-2.0 -g

librygel_mediathek_la_LIBADD = $(LIBGUPNP_LIBS) \
			       $(LIBGUPNP_AV_LIBS) \
			       $(LIBDBUS_GLIB_LIBS) \
			       $(LIBGSTREAMER_LIBS) \
			       $(GEE_LIBS) \
                               $(UUID_LIBS)

librygel_mediathek_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
