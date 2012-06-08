include ../../../common.am

lib_LTLIBRARIES = librygel-renderer.la

librygel_renderer_la_SOURCES = \
	rygel-playbin-player.vala \
	rygel-playbin-plugin.vala

librygel_renderer_la_VALAFLAGS = \
	-H rygel-renderer.h --library=rygel-renderer-1.0 \
	$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_renderer_la_LIBADD = $(RYGEL_COMMON_LIBS)
#librygel_renderer_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)

plugin_LTLIBRARIES = librygel-playbin.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Playbin"'

librygel_playbin_la_SOURCES = rygel-module.vala
librygel_playbin_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS) --pkg rygel-renderer-1.0 --vapidir=$(builddir)
librygel_playbin_la_LIBADD = $(RYGEL_COMMON_LIBS) librygel-renderer.la
librygel_playbin_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
