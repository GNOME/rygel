include ../../../common.am

plugin_LTLIBRARIES = librygel-mpris.la

AM_CFLAGS += -DG_LOG_DOMAIN='"MPRIS"' \
	-I$(top_builddir)/src/librygel-renderer

librygel_mpris_la_SOURCES = \
	rygel-mpris-player.vala \
	rygel-mpris-plugin.vala \
	rygel-mpris-plugin-factory.vala \
	rygel-mpris-interfaces.vala \
	$(top_builddir)/src/librygel-renderer/rygel-renderer-1.0.vapi

librygel_mpris_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_mpris_la_LIBADD = $(RYGEL_COMMON_LIBS) \
	$(top_builddir)/src/librygel-renderer/librygel-renderer-1.0.la
librygel_mpris_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
