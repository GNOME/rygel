include $(top_srcdir)/common.am

engine_LTLIBRARIES = librygel-media-engine-simple.la

AM_CFLAGS += -DG_LOG_DOMAIN='"MediaEngine-Simple"'

librygel_media_engine_simple_la_SOURCES = \
	rygel-simple-media-engine.vala \
	rygel-simple-data-source.vala

librygel_media_engine_simple_la_VALAFLAGS = \
	$(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)

librygel_media_engine_simple_la_LIBADD = $(RYGEL_COMMON_SERVER_LIBS)
librygel_media_engine_simple_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
