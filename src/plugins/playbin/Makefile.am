include ../../../common.am

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

plugin_LTLIBRARIES = librygel-playbin.la

librygel_playbin_la_SOURCES = rygel-module.vala rygel-renderer-1.0.vapi
librygel_playbin_la_CFLAGS = $(AM_CFLAGS) -DG_LOG_DOMAIN='"Playbin"'
librygel_playbin_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_playbin_la_LIBADD = $(RYGEL_COMMON_LIBS) librygel-renderer-1.0.la
librygel_playbin_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
