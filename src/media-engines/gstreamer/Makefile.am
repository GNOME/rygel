include $(top_srcdir)/common.am

engine_LTLIBRARIES = librygel-media-engine-gst.la
engine_DATA = media-engine-gst.plugin

librygel_media_engine_gst_la_SOURCES = \
	rygel-aac-transcoder.vala \
	rygel-audio-transcoder.vala \
	rygel-avc-transcoder.vala \
	rygel-gst-data-source.vala \
	rygel-gst-media-engine.vala \
	rygel-gst-sink.vala \
	rygel-gst-transcoder.vala \
	rygel-gst-utils.vala \
	rygel-l16-transcoder.vala \
	rygel-mp2ts-transcoder.vala \
	rygel-mp3-transcoder.vala \
	rygel-video-transcoder.vala \
	rygel-wmv-transcoder.vala

librygel_media_engine_gst_la_VALAFLAGS = \
	--enable-experimental \
	$(RYGEL_MEDIA_ENGINE_GSTREAMER_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_media_engine_gst_la_CFLAGS = \
	$(RYGEL_MEDIA_ENGINE_GSTREAMER_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"MediaEngine-GStreamer"' \
	-DPRESET_DIR='"$(presetdir)"'

librygel_media_engine_gst_la_LIBADD = \
	$(RYGEL_MEDIA_ENGINE_GSTREAMER_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)

librygel_media_engine_gst_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = media-engine-gst.plugin.in
