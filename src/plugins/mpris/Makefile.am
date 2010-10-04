if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-mpris.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(UUID_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

librygel_mpris_la_SOURCES = rygel-mpris-player.vala \
			    rygel-mpris-plugin.vala \
			    rygel-mpris-plugin-factory.vala \
			    rygel-mpris-interfaces.vala

librygel_mpris_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
			      --vapidir=$(srcdir) \
			      --pkg rygel-1.0 --pkg rygel-build-config \
			      --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
			      --pkg gee-1.0 --pkg gstreamer-0.10 -g

librygel_mpris_la_LIBADD = $(LIBGUPNP_LIBS) \
			   $(LIBGUPNP_AV_LIBS) \
			   $(GEE_LIBS) \
			   $(LIBGSTREAMER_LIBS) \
			   $(UUID_LIBS)
librygel_mpris_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
