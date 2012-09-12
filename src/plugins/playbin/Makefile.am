include ../../../common.am

plugin_LTLIBRARIES = librygel-playbin.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Playbin"' \
	$(LIBGSTREAMER_CFLAGS)

librygel_playbin_la_SOURCES = rygel-module.vala
librygel_playbin_la_CFLAGS = $(AM_CFLAGS)
librygel_playbin_la_VALAFLAGS = $(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)
librygel_playbin_la_LIBADD = $(RYGEL_COMMON_RENDERER_LIBS)
librygel_playbin_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
