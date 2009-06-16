if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-test.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"'

librygel_test_la_SOURCES = rygel-test-content-dir.vala \
			   rygel-test-root-container.vala \
			   rygel-test-item.vala \
			   rygel-test-audio-item.vala \
			   rygel-test-video-item.vala \
			   rygel-test-plugin.vala

librygel_test_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
			     --pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
			     --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
			     --pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10

librygel_test_la_LIBADD = $(LIBGUPNP_LIBS) \
			  $(LIBGUPNP_AV_LIBS) \
			  $(LIBDBUS_GLIB_LIBS) \
			  $(LIBGSTREAMER_LIBS) \
			  $(GEE_LIBS)

librygel_test_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
