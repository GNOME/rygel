plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-test.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-test-content-dir.c \
		rygel-test-root-container.c \
		rygel-test-item.c \
		rygel-test-audio-item.c \
		rygel-test-video-item.c \
		rygel-test-plugin.c

$(BUILT_SOURCES) : rygel-test.stamp

librygel_test_la_SOURCES = rygel-test-content-dir.c \
			   rygel-test-content-dir.vala \
			   rygel-test-root-container.c \
			   rygel-test-root-container.vala \
			   rygel-test-item.c \
			   rygel-test-item.vala \
			   rygel-test-audio-item.c \
			   rygel-test-audio-item.vala \
			   rygel-test-video-item.c \
			   rygel-test-video-item.vala \
			   rygel-test-plugin.c \
			   rygel-test-plugin.vala

rygel-test.stamp: $(filter %.vala,$(librygel_test_la_SOURCES))
	$(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
        --pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10 $^
	touch $@

librygel_test_la_LIBADD = $(LIBGUPNP_LIBS) \
			  $(LIBGUPNP_AV_LIBS) \
                          $(LIBDBUS_GLIB_LIBS) \
	                  $(LIBGSTREAMER_LIBS) \
                          $(GEE_LIBS) \
			  $(LIBGCONF_LIBS)
librygel_test_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-test.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-test.stamp
