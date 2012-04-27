include ../../../common.am

plugin_LTLIBRARIES = librygel-gst-launch.la

AM_CFLAGS += -DG_LOG_DOMAIN='"GstLaunch"'

librygel_gst_launch_la_SOURCES = \
	rygel-gst-launch-plugin.vala \
	rygel-gst-launch-root-container.vala \
	rygel-gst-launch-item.vala \
	rygel-gst-launch-audio-item.vala \
	rygel-gst-launch-video-item.vala

librygel_gst_launch_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_gst_launch_la_LIBADD = $(RYGEL_COMMON_LIBS)
librygel_gst_launch_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
