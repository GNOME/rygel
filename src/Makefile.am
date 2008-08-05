if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/gupnp-media-server
endif

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"'

bin_PROGRAMS = gupnp-media-server

BUILT_SOURCES = gupnp-media-server.stamp \
		gupnp-media-server.h \
		gupnp-media-server.c \
		gupnp-content-directory.h \
		gupnp-content-directory.c \
		gupnp-connection-manager.h \
		gupnp-connection-manager.c \
		gupnp-media-receiver-registrar.h \
		gupnp-media-receiver-registrar.c \
		gupnp-media-tracker.h \
		gupnp-media-tracker.c

gupnp_media_server_SOURCES = cstuff.c \
			     cstuff.h \
			     gupnp-media-server.h \
			     gupnp-media-server.c \
			     gupnp-media-server.vala \
			     gupnp-content-directory.h \
			     gupnp-content-directory.c \
			     gupnp-content-directory.vala \
			     gupnp-connection-manager.h \
			     gupnp-connection-manager.c \
			     gupnp-connection-manager.vala \
			     gupnp-media-receiver-registrar.h \
			     gupnp-media-receiver-registrar.c \
			     gupnp-media-receiver-registrar.vala \
			     gupnp-media-tracker.h \
			     gupnp-media-tracker.c \
			     gupnp-media-tracker.vala \
			     gupnp-metadata-extractor.c \
			     gupnp-metadata-extractor.h \
			     gupnp-metadata-extractor.vala

gupnp-media-server.stamp: $(filter %.vala,$(gupnp_media_server_SOURCES))
	$(VALAC) -C --vapidir=$(srcdir) --pkg cstuff --pkg gupnp-1.0 \
	--pkg gupnp-av-1.0 --pkg dbus-glib-1 --pkg gconf-2.0 \
	--pkg gstreamer-0.10 $^
	touch $@

gupnp_media_server_LDADD = $(LIBGUPNP_LIBS) \
			   $(LIBGUPNP_AV_LIBS) \
			   $(LIBGCONF_LIBS) \
			   $(LIBDBUS_GLIB_LIBS) \
			   $(LIBGSTREAMER_LIBS)
gupnp_media_server_LDFLAGS = -export-dynamic

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = cstuff.vapi
