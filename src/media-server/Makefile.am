if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/gupnp-media-server
endif

if UNINSTALLED
plugindir = $(abs_top_builddir)/src/media-providers
else
plugindir = $(libdir)/gupnp-media-server-1.0
endif

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -DPLUGIN_DIR='"$(plugindir)"'

bin_PROGRAMS = gupnp-media-server

BUILT_SOURCES = gupnp-media-server-1.0.vapi \
		gupnp-media-server.stamp \
		gupnp-media-server.h \
		gupnp-media-server.c \
		gupnp-content-directory.h \
		gupnp-content-directory.c \
		gupnp-connection-manager.h \
		gupnp-connection-manager.c \
		gupnp-media-receiver-registrar.h \
		gupnp-media-receiver-registrar.c \
		gupnp-media-provider.h \
		gupnp-media-provider.c \
		gupnp-media-object.c \
		gupnp-media-object.h \
		gupnp-media-container.c \
		gupnp-media-container.h \
		gupnp-media-item.c \
		gupnp-media-item.h \
		gupnp-media-manager.h \
		gupnp-media-manager.c

gupnp_media_server_SOURCES = gupnp-media-server-1.0.vapi \
			     cstuff.c \
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
			     gupnp-media-provider.h \
			     gupnp-media-provider.c \
			     gupnp-media-object.c \
			     gupnp-media-object.h \
			     gupnp-media-container.c \
			     gupnp-media-container.h \
			     gupnp-media-item.c \
			     gupnp-media-item.h \
			     gupnp-media-manager.h \
			     gupnp-media-manager.c \
			     gupnp-media-manager.vala \
			     gupnp-metadata-extractor.c \
			     gupnp-metadata-extractor.h \
			     gupnp-metadata-extractor.vala

gupnp-media-server.stamp: $(filter %.vala,$(gupnp_media_server_SOURCES))
	$(VALAC) -C --vapidir=$(srcdir) --pkg gupnp-media-server-1.0 \
	--pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
	--pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 $^
	touch $@

gupnp_media_server_LDADD = $(LIBGUPNP_LIBS) \
			   $(LIBGUPNP_AV_LIBS) \
			   $(LIBGCONF_LIBS) \
			   $(LIBGSTREAMER_LIBS) \
			   $(GIO_LIBS)
gupnp_media_server_LDFLAGS = -export-dynamic

VAPI_FILES = gupnp-media-server-1.0.vapi

gupnp-media-server-1.0.vapi: gupnp-media-provider.vala \
			     gupnp-media-object.vala \
			     gupnp-media-container.vala \
			     gupnp-media-item.vala
	$(VALAC) -C --library=gupnp-media-server-1.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	$^

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = cstuff.vapi
