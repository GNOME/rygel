if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

if UNINSTALLED
plugindir = $(abs_top_builddir)/src/media-providers
else
plugindir = $(libdir)/rygel-1.0
endif

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -DPLUGIN_DIR='"$(plugindir)"'

bin_PROGRAMS = rygel

BUILT_SOURCES = rygel-1.0.vapi \
		rygel.stamp \
		rygel-media-server.h \
		rygel-media-server.c \
		rygel-media-server-factory.h \
		rygel-media-server-factory.c \
		rygel-main.h \
		rygel-main.c \
		rygel-content-directory.h \
		rygel-content-directory.c \
		rygel-plugin.h \
		rygel-plugin.c \
		rygel-plugin-loader.h \
		rygel-plugin-loader.c \
		rygel-resource-info.h \
		rygel-resource-info.c \
		rygel-connection-manager.h \
		rygel-connection-manager.c \
		rygel-media-receiver-registrar.h \
		rygel-media-receiver-registrar.c \
		rygel-media-object.c \
		rygel-media-object.h \
		rygel-media-container.c \
		rygel-media-container.h \
		rygel-media-item.c \
		rygel-media-item.h

rygel_SOURCES = rygel-1.0.vapi \
		cstuff.c \
		cstuff.h \
		rygel-media-server.h \
		rygel-media-server.c \
		rygel-media-server.vala \
		rygel-media-server-factory.h \
		rygel-media-server-factory.c \
		rygel-media-server-factory.vala \
		rygel-main.h \
		rygel-main.c \
		rygel-main.vala \
		rygel-content-directory.h \
		rygel-content-directory.c \
		rygel-plugin.h \
		rygel-plugin.c \
		rygel-plugin-loader.h \
		rygel-plugin-loader.c \
		rygel-plugin-loader.vala \
		rygel-resource-info.h \
		rygel-resource-info.c \
		rygel-connection-manager.h \
		rygel-connection-manager.c \
		rygel-media-receiver-registrar.h \
		rygel-media-receiver-registrar.c \
		rygel-media-object.c \
		rygel-media-object.h \
		rygel-media-container.c \
		rygel-media-container.h \
		rygel-media-item.c \
		rygel-media-item.h \
		rygel-metadata-extractor.c \
		rygel-metadata-extractor.h \
		rygel-metadata-extractor.vala

rygel.stamp: $(filter %.vala,$(rygel_SOURCES))
	$(VALAC) -C --vapidir=$(srcdir) --pkg rygel-1.0 \
	--pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
	--pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 $^
	touch $@

rygel_LDADD = $(LIBGUPNP_LIBS) \
	      $(LIBGUPNP_AV_LIBS) \
	      $(LIBGCONF_LIBS) \
	      $(LIBGSTREAMER_LIBS) \
	      $(GIO_LIBS)
rygel_LDFLAGS = -export-dynamic

VAPI_FILES = rygel-1.0.vapi

rygel-1.0.vapi: rygel-content-directory.vala \
		rygel-connection-manager.vala \
		rygel-media-receiver-registrar.vala \
		rygel-resource-info.vala \
		rygel-plugin.vala \
		rygel-media-object.vala \
		rygel-media-container.vala \
		rygel-media-item.vala
	$(VALAC) -C --library=rygel-1.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	$^

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = cstuff.vapi
