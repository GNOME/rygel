include ../../../common.am

plugin_LTLIBRARIES = librygel-mpris.la

AM_CFLAGS += -DG_LOG_DOMAIN='"MPRIS"' \
	$(LIBGSTREAMER_CFLAGS)

librygel_mpris_la_SOURCES = \
	rygel-mpris-player.vala \
	rygel-mpris-plugin.vala \
	rygel-mpris-plugin-factory.vala \
	rygel-mpris-interfaces.vala

librygel_mpris_la_VALAFLAGS = $(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)
librygel_mpris_la_LIBADD = $(RYGEL_COMMON_RENDERER_LIBS) $(LIBGIO_LIBS)
librygel_mpris_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
