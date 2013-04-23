include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-media-export.la
plugin_DATA = media-export.plugin

librygel_media_export_la_SOURCES = \
	rygel-media-export-plugin.vala \
	rygel-media-export-database.vala \
	rygel-media-export-database-cursor.vala \
	rygel-media-export-sqlite-wrapper.vala \
	rygel-media-export-db-container.vala \
	rygel-media-export-sql-factory.vala \
	rygel-media-export-media-cache.vala \
	rygel-media-export-sql-operator.vala \
	rygel-media-export-sql-function.vala \
	rygel-media-export-media-cache-upgrader.vala \
	rygel-media-export-metadata-extractor.vala \
	rygel-media-export-null-container.vala \
	rygel-media-export-dummy-container.vala \
	rygel-media-export-root-container.vala \
	rygel-media-export-query-container.vala \
	rygel-media-export-query-container-factory.vala \
	rygel-media-export-node-query-container.vala \
	rygel-media-export-leaf-query-container.vala \
	rygel-media-export-recursive-file-monitor.vala \
	rygel-media-export-harvester.vala \
	rygel-media-export-harvesting-task.vala \
	rygel-media-export-item-factory.vala \
	rygel-media-export-jpeg-writer.vala \
	rygel-media-export-object-factory.vala \
	rygel-media-export-writable-db-container.vala \
	rygel-media-export-playlist-root-container.vala \
	rygel-media-export-playlist-container.vala \
	rygel-media-export-music-item.vala \
	rygel-media-export-video-item.vala \
	rygel-media-export-photo-item.vala \
	rygel-media-export-playlist-item.vala \
	rygel-media-export-trackable-db-container.vala \
	rygel-media-export-updatable-object.vala \
	rygel-media-export-collate.c

librygel_media_export_la_VALAFLAGS = \
	--enable-experimental \
	--internal-vapi rygel-media-export.vapi \
	--internal-header rygel-media-export-internal.h \
	--header rygel-media-export.h \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_media_export_la_CFLAGS = \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"MediaExport"'
librygel_media_export_la_LIBADD = \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)

librygel_media_export_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = media-export.plugin.in
