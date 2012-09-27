include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-test.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Test"' \
	-I$(top_srcdir)/src/media-engines/gstreamer \
	$(LIBGSTREAMER_CFLAGS)

librygel_test_la_SOURCES = \
	rygel-test-root-container.vala \
	rygel-test-audio-item.vala \
	rygel-test-video-item.vala \
	rygel-test-plugin.vala \
	$(top_srcdir)/src/media-engines/gstreamer/rygel-media-engine-gst.vapi

librygel_test_la_VALAFLAGS = \
	--pkg gstreamer-0.10 \
	$(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)

librygel_test_la_LIBADD = \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_SERVER_LIBS)
librygel_test_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
