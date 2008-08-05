plugindir = $(libdir)/gupnp-media-server-1.0

plugin_LTLIBRARIES = libgupnp-media-tracker.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    -I$(top_srcdir)/src/media-server

BUILT_SOURCES = gupnp-media-tracker.stamp \
		gupnp-media-tracker.h \
		gupnp-media-tracker.c

libgupnp_media_tracker_la_SOURCES = gupnp-media-tracker.h \
			            gupnp-media-tracker.c \
				    gupnp-media-tracker.vala

gupnp-media-tracker.stamp: $(filter %.vala,$(libgupnp_media_tracker_la_SOURCES))
	$(VALAC) -C --vapidir=$(top_srcdir)/src/media-server \
	--pkg gupnp-media-server-1.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 $^
	touch $@

libgupnp_media_tracker_la_LIBADD = $(LIBGUPNP_LIBS) \
			       	   $(LIBGUPNP_AV_LIBS) \
				   $(LIBDBUS_GLIB_LIBS)
libgupnp_media_tracker_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
