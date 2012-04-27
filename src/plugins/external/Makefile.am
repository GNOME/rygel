include ../../../common.am

plugin_LTLIBRARIES = librygel-external.la

AM_CFLAGS += -DG_LOG_DOMAIN='"External"'

librygel_external_la_SOURCES = \
	rygel-external-container.vala \
	rygel-external-dummy-container.vala \
	rygel-external-item-factory.vala \
	rygel-external-album-art-factory.vala \
	rygel-external-thumbnail-factory.vala \
	rygel-external-plugin.vala \
	rygel-external-interfaces.vala \
	rygel-external-plugin-factory.vala \
	rygel-external-icon-factory.vala

librygel_external_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_external_la_LIBADD = $(RYGEL_COMMON_LIBS)
librygel_external_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
