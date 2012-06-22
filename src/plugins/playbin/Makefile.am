include ../../../common.am

lib_LTLIBRARIES = librygel-renderer.la

librygel_renderer_la_SOURCES = \
	rygel-playbin-player.vala \
	rygel-playbin-plugin.vala \
	rygel-playbin-renderer.vala

librygel_renderer_la_VALAFLAGS = \
	-H rygel-renderer.h --library=rygel-renderer-1.0 \
	$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_renderer_la_LIBADD = $(RYGEL_COMMON_LIBS)

rygel-renderer.h rygel-renderer-1.0.vapi: librygel_renderer_la_vala.stamp

plugin_LTLIBRARIES = librygel-playbin.la

librygel_playbin_la_SOURCES = rygel-module.vala rygel-renderer-1.0.vapi
librygel_playbin_la_CFLAGS = $(AM_CFLAGS) -DG_LOG_DOMAIN='"Playbin"'
librygel_playbin_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_playbin_la_LIBADD = $(RYGEL_COMMON_LIBS) librygel-renderer.la
librygel_playbin_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
