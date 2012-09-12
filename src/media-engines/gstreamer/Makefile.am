include $(top_srcdir)/common.am

engine_LTLIBRARIES = librygel-media-engine-gst.la

AM_CFLAGS += -DG_LOG_DOMAIN='"MediaEngine-GStreamer"' \
	$(GST_PBU_CFLAGS) \
	$(LIBGUPNP_DLNA_CFLAGS)

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
	--pkg gstreamer-base-0.10 \
	--pkg gstreamer-pbutils-0.10 \
	--pkg gupnp-dlna-1.0 \
	--library rygel-media-engine-gst \
	--use-header \
	--header=rygel-media-engine-gst.h \
	$(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)

rygel-media-engine-gst.h rygel-media-engine-gstreamer.vapi: librygel_media_engine_gst_la_vala.stamp

librygel_media_engine_gst_la_LIBADD = \
	$(GST_PBU_LIBS) \
	$(LIBGUPNP_DLNA_LIBS) \
	$(RYGEL_COMMON_SERVER_LIBS)

librygel_media_engine_gst_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = \
	rygel-media-engine-gst.vapi \
	rygel-media-engine-gst.h
