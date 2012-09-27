include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-gst-launch.la

AM_CFLAGS += -DG_LOG_DOMAIN='"GstLaunch"' \
	-I$(top_srcdir)/src/media-engines/gstreamer \
	$(LIBGSTREAMER_CFLAGS)

librygel_gst_launch_la_SOURCES = \
	rygel-gst-launch-plugin.vala \
	rygel-gst-launch-root-container.vala \
	rygel-gst-launch-item.vala \
	rygel-gst-launch-audio-item.vala \
	rygel-gst-launch-video-item.vala \
	$(top_srcdir)/src/media-engines/gstreamer/rygel-media-engine-gst.vapi

librygel_gst_launch_la_VALAFLAGS = \
	--pkg gstreamer-0.10 \
	$(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)
librygel_gst_launch_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_SERVER_LIBS)
librygel_gst_launch_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
