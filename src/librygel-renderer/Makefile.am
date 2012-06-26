include ../../common.am

lib_LTLIBRARIES = librygel-renderer-1.0.la

LIBRYGEL_RENDERER_VERSION=0:0:0

librygel_renderer_1_0_la_SOURCES = \
	rygel-playbin-player.vala \
	rygel-playbin-plugin.vala \
	rygel-playbin-renderer.vala

librygel_renderer_1_0_la_VALAFLAGS = \
	-H rygel-renderer.h --library=rygel-renderer-1.0 \
	$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_renderer_1_0_la_LIBADD = $(RYGEL_COMMON_LIBS)
librygel_renderer_1_0_la_LDFLAGS = -version-info $(LIBRYGEL_RENDERER_VERSION)

rygel-renderer.h rygel-renderer-1.0.vapi: librygel_renderer_1_0_la_vala.stamp
