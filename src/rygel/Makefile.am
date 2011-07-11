include ../../common.am

AM_CFLAGS += \
	$(LIBGUPNP_DLNA_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(GST_PBU_CFLAGS) \
	-DSMALL_ICON_DIR='"$(smallicondir)"' \
	-DBIG_ICON_DIR='"$(bigicondir)"' -include config.h \
	-DLOCALEDIR=\""$(datadir)/locale"\" -DG_LOG_DOMAIN='"Rygel"'

librygelincdir = $(includedir)/rygel-1.0

librygelinc_HEADERS = rygel.h

bin_PROGRAMS = rygel

BUILT_SOURCES = \
	rygel-1.0.vapi \
	rygel.h

rygel_SOURCES = \
	$(VAPI_SOURCE_FILES) \
	rygel-http-item-uri.vala \
	rygel-dbus-service.vala \
	rygel-root-device.vala \
	rygel-root-device-factory.vala \
	rygel-xml-utils.vala \
	rygel-signal-handler.vala \
	rygel-main.vala

VAPI_SOURCE_FILES = \
	rygel-configuration.vala \
	rygel-user-config.vala \
	rygel-meta-config.vala \
	rygel-cmdline-config.vala \
	rygel-environment-config.vala \
	rygel-content-directory.vala \
	rygel-connection-manager.vala \
	rygel-source-connection-manager.vala \
	rygel-sink-connection-manager.vala \
	rygel-av-transport.vala \
	rygel-rendering-control.vala \
	rygel-transcode-manager.vala \
	rygel-http-server.vala \
	rygel-state-machine.vala \
	rygel-http-request.vala \
	rygel-http-get-handler.vala \
	rygel-http-get.vala \
	rygel-http-post.vala \
	rygel-http-identity-handler.vala \
	rygel-http-transcode-handler.vala \
	rygel-http-seek.vala \
	rygel-http-byte-seek.vala \
	rygel-http-time-seek.vala \
	rygel-http-response.vala \
	rygel-http-gst-sink.vala \
	rygel-resource-info.vala \
	rygel-icon-info.vala \
	rygel-plugin.vala \
	rygel-media-server-plugin.vala \
	rygel-media-renderer-plugin.vala \
	rygel-plugin-loader.vala \
	rygel-media-object.vala \
	rygel-media-objects.vala \
	rygel-media-container.vala \
	rygel-simple-container.vala \
	rygel-writable-container.vala \
	rygel-searchable-container.vala \
	rygel-media-item.vala \
	rygel-audio-item.vala \
	rygel-music-item.vala \
	rygel-visual-item.vala \
	rygel-video-item.vala \
	rygel-image-item.vala \
	rygel-photo-item.vala \
	rygel-thumbnail.vala \
	rygel-thumbnailer.vala \
	rygel-media-art-store.vala \
	rygel-subtitle.vala \
	rygel-subtitle-manager.vala \
	rygel-media-query-action.vala \
	rygel-browse.vala \
	rygel-search.vala \
	rygel-xbox-hacks.vala \
	rygel-import-resource.vala \
	rygel-item-creator.vala \
	rygel-item-destroyer.vala \
	rygel-item-removal-queue.vala \
	rygel-search-expression.vala \
	rygel-relational-expression.vala \
	rygel-logical-expression.vala \
	rygel-search-criteria-parser.vala \
	rygel-transcoder.vala \
	rygel-mp2ts-transcoder.vala \
	rygel-mp3-transcoder.vala \
	rygel-l16-transcoder.vala \
	rygel-wmv-transcoder.vala \
	rygel-aac-transcoder.vala \
	rygel-gst-utils.vala \
	rygel-media-receiver-registrar.vala \
	rygel-log-handler.vala \
	rygel-media-player.vala \
	rygel-changelog.vala \
	rygel-volume.vala \
	rygel-free-desktop-interfaces.vala \
	rygel-dbus-interface.vala

rygel_VALAFLAGS = \
	-H rygel.h -C --library=rygel-1.0 \
	--pkg rygel-misc \
	--pkg gstreamer-0.10 \
	--pkg gstreamer-base-0.10 \
	--pkg gupnp-dlna-1.0 \
	--pkg posix \
	$(RYGEL_COMMON_VALAFLAGS)

rygel_LDADD = \
	librygel-configuration.a \
	$(RYGEL_COMMON_LDADD) \
	$(LIBGUPNP_DLNA_LIBS) \
	$(GST_PBU_LIBS) \
	$(GIO_LIBS) \
	$(LIBSOUP_LIBS)

rygel_LDFLAGS = -export-dynamic

VAPI_FILES = rygel-1.0.vapi
DEPS_FILES = rygel-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)
rygel-1.0.vapi rygel.h: $(VAPI_SOURCE_FILES)

noinst_LIBRARIES = librygel-configuration.a

librygel_configuration_a_SOURCES = \
	rygel-configuration.c \
	rygel-user-config.c \
	rygel-meta-config.c \
	rygel-cmdline-config.c \
	rygel-environment-config.c \
	rygel-dbus-interface.c \
	rygel-free-desktop-interfaces.c

MAINTAINERCLEANFILES += $(BUILT_SOURCES)

EXTRA_DIST = \
	rygel-build-config.vapi \
	rygel-misc.vapi \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(BUILT_SOURCES)

