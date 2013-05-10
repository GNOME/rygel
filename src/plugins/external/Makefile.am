include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-external.la
plugin_DATA = external.plugin

librygel_external_la_SOURCES = \
	rygel-external-container.vala \
	rygel-external-dummy-container.vala \
	rygel-external-item-factory.vala \
	rygel-external-album-art-factory.vala \
	rygel-external-thumbnail-factory.vala \
	rygel-external-plugin.vala \
	rygel-external-interfaces.vala \
	rygel-external-plugin-factory.vala \
	rygel-external-icon-factory.vala \
	rygel-external-variant-util.vala

librygel_external_la_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_external_la_CFLAGS = \
	$(RYGEL_PLUGIN_EXTERNAL_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"External"'
librygel_external_la_LIBADD = \
	$(RYGEL_PLUGIN_EXTERNAL_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
librygel_external_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST=external.plugin.in
