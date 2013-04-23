include $(top_srcdir)/common.am

engine_LTLIBRARIES = librygel-media-engine-simple.la
engine_DATA = media-engine-simple.plugin

librygel_media_engine_simple_la_SOURCES = \
	rygel-simple-media-engine.vala \
	rygel-simple-data-source.vala

librygel_media_engine_simple_la_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_media_engine_simple_la_CFLAGS = \
	$(LIBRYGEL_SERVER_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"MediaEngine-Simple"'
librygel_media_engine_simple_la_LIBADD = \
	$(LIBRYGEL_SERVER_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
librygel_media_engine_simple_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = media-engine-simple.plugin.in
