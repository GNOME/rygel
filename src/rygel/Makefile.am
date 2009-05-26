if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

if UNINSTALLED
plugindir = $(abs_top_builddir)/src/plugins
else
plugindir = $(libdir)/rygel-1.0
endif

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    $(LIBSOUP_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -DPLUGIN_DIR='"$(plugindir)"' -include config.h

librygelincdir = $(includedir)/rygel-1.0

librygelinc_HEADERS = rygel.h

bin_PROGRAMS = rygel

BUILT_SOURCES = rygel-1.0.vapi \
		rygel.h \
		rygel-media-server.c \
		rygel-media-server-factory.c \
		rygel-configuration.c \
		rygel-main.c \
		rygel-content-directory.c \
		rygel-browse.c \
		rygel-didl-lite-writer.c \
		rygel-plugin.c \
		rygel-plugin-loader.c \
		rygel-transcode-manager.c \
		rygel-http-server.c \
		rygel-state-machine.c \
		rygel-http-request.c \
		rygel-http-response.c \
		rygel-live-response.c \
		rygel-seekable-response.c \
		rygel-resource-info.c \
		rygel-icon-info.c \
		rygel-connection-manager.c \
		rygel-media-object.c \
		rygel-media-container.c \
		rygel-simple-async-result.c \
		rygel-media-item.c

$(BUILT_SOURCES) : rygel.stamp

rygel_SOURCES = $(VAPI_SOURCE_FILES) \
		rygel-media-server.c \
		rygel-media-server.vala \
		rygel-media-server-factory.c \
		rygel-media-server-factory.vala \
		rygel-main.c \
		rygel-main.vala \
		rygel-content-directory.c \
		rygel-browse.c \
		rygel-didl-lite-writer.c \
		rygel-plugin.c \
		rygel-plugin-loader.c \
		rygel-transcode-manager.c \
		rygel-http-server.c \
		rygel-state-machine.c \
		rygel-http-request.c \
		rygel-http-response.c \
		rygel-live-response.c \
		rygel-seekable-response.c \
		rygel-resource-info.c \
		rygel-icon-info.c \
		rygel-connection-manager.c \
		rygel-media-object.c \
		rygel-media-container.c \
		rygel-simple-async-result.c \
		rygel-media-item.c \
		rygel-transcoder.c \
		rygel-mp2ts-transcoder.c \
		rygel-mp3-transcoder.c \
		rygel-l16-transcoder.c \
		rygel-mp2ts-transcoder-bin.c \
		rygel-mp3-transcoder-bin.c \
		rygel-l16-transcoder-bin.c \
		rygel-gst-utils.c

rygel.stamp: $(filter %.vala,$(rygel_SOURCES))
	$(VALAC) -C --vapidir=$(srcdir) \
	--pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
	--pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 --pkg gee-1.0 $^
	touch $@

rygel_LDADD = $(LIBGUPNP_LIBS) \
	      $(LIBGUPNP_AV_LIBS) \
	      $(LIBGCONF_LIBS) \
	      $(LIBGSTREAMER_LIBS) \
	      $(GIO_LIBS) \
	      $(GEE_LIBS) \
	      $(UUID_LIBS) \
	      $(LIBSOUP_LIBS) \
	      librygel-configuration.a
rygel_LDFLAGS = -export-dynamic

VAPI_FILES = rygel-1.0.vapi
DEPS_FILES = rygel-1.0.deps

VAPI_SOURCE_FILES = rygel-configuration.vala \
		    rygel-content-directory.vala \
		    rygel-connection-manager.vala \
		    rygel-transcode-manager.vala \
		    rygel-http-server.vala \
		    rygel-state-machine.vala \
		    rygel-http-request.vala \
		    rygel-http-response.vala \
		    rygel-live-response.vala \
		    rygel-seekable-response.vala \
		    rygel-resource-info.vala \
		    rygel-icon-info.vala \
		    rygel-plugin.vala \
		    rygel-plugin-loader.vala \
		    rygel-media-object.vala \
		    rygel-media-container.vala \
		    rygel-simple-async-result.vala \
		    rygel-media-item.vala \
		    rygel-browse.vala \
		    rygel-didl-lite-writer.vala \
		    rygel-transcoder.vala \
		    rygel-mp2ts-transcoder.vala \
		    rygel-mp3-transcoder.vala \
		    rygel-l16-transcoder.vala \
		    rygel-mp2ts-transcoder-bin.vala \
		    rygel-mp3-transcoder-bin.vala \
		    rygel-l16-transcoder-bin.vala \
		    rygel-gst-utils.vala

rygel-1.0.vapi: $(VAPI_SOURCE_FILES)
	$(VALAC) -H rygel.h -C --library=rygel-1.0 --vapidir=$(srcdir) \
	--pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg gconf-2.0 \
	--pkg gee-1.0 --pkg gstreamer-0.10 \
	$(VAPI_SOURCE_FILES)

noinst_LIBRARIES = librygel-configuration.a

librygel_configuration_a_SOURCES = rygel-configuration.c \
				   cstuff.c \
                                   cstuff.h

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

CLEANFILES = $(BUILT_SOURCES) rygel.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = cstuff.vapi \
             $(VAPI_FILES) \
             $(DEPS_FILES) \
             $(VAPI_SOURCE_FILES) \
             $(BUILT_SOURCES) \
	     rygel.stamp
