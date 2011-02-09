if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-playbin.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
            $(LIBGUPNP_AV_CFLAGS) \
            $(GEE_CFLAGS) \
            $(LIBGSTREAMER_CFLAGS) \
            $(UUID_CFLAGS) \
            -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"' \
	    -include config.h -DG_LOG_DOMAIN='"Playbin"'

librygel_playbin_la_SOURCES = rygel-playbin-player.vala \
			      rygel-playbin-plugin.vala

librygel_playbin_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
				--vapidir=$(srcdir) \
				--pkg rygel-1.0 --pkg rygel-build-config \
				--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
				--pkg gee-1.0 --pkg gstreamer-0.10 -g

librygel_playbin_la_LIBADD = $(LIBGUPNP_LIBS) \
			     $(LIBGUPNP_AV_LIBS) \
			     $(LIBGSTREAMER_LIBS) \
			     $(GEE_LIBS) \
			     $(UUID_LIBS)
librygel_playbin_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in

vala-clean:
	rm -f `find . -name "*.stamp"`
