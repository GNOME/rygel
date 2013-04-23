include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-gst-launch.la
plugin_DATA = gst-launch.plugin

librygel_gst_launch_la_SOURCES = \
	rygel-gst-launch-plugin.vala \
	rygel-gst-launch-root-container.vala \
	rygel-gst-launch-item.vala \
	rygel-gst-launch-audio-item.vala \
	rygel-gst-launch-video-item.vala

librygel_gst_launch_la_VALAFLAGS = \
	--enable-experimental \
	$(RYGEL_PLUGIN_GST_LAUNCH_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_gst_launch_la_CFLAGS = \
	$(RYGEL_PLUGIN_GST_LAUNCH_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"GstLaunch"'
librygel_gst_launch_la_LIBADD = \
	$(RYGEL_PLUGIN_GST_LAUNCH_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
librygel_gst_launch_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = gst-launch.plugin.in
