include ../../../common.am

plugin_LTLIBRARIES = librygel-test.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Test"'

librygel_test_la_SOURCES = \
	rygel-test-root-container.vala \
	rygel-test-audio-item.vala \
	rygel-test-video-item.vala \
	rygel-test-plugin.vala

librygel_test_la_VALAFLAGS = $(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)
librygel_test_la_LIBADD = $(RYGEL_COMMON_SERVER_LIBS)
librygel_test_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
