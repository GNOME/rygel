include ../../../common.am

plugin_LTLIBRARIES = librygel-media-export.la

AM_CFLAGS += \
	$(LIBGUPNP_DLNA_CFLAGS) \
	$(LIBSQLITE3_CFLAGS) \
	$(GSTREAMER_TAG_CFLAGS) \
	$(GSTREAMER_APP_CFLAGS) \
	-DG_LOG_DOMAIN='"MediaExport"'

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
	rygel-media-export-dbus-service.vala \
	rygel-media-export-recursive-file-monitor.vala \
	rygel-media-export-harvester.vala \
	rygel-media-export-harvesting-task.vala \
	rygel-media-export-item.vala \
	rygel-media-export-jpeg-writer.vala \
	rygel-media-export-object-factory.vala \
	rygel-media-export-writable-db-container.vala \
	rygel-media-export-music-item.vala \
	rygel-media-export-video-item.vala \
	rygel-media-export-photo-item.vala \
	rygel-media-export-collate.c

librygel_media_export_la_VALAFLAGS = \
	--pkg gupnp-dlna-1.0 \
	--pkg gstreamer-tag-0.10 \
	--pkg gstreamer-app-0.10 \
	--pkg sqlite3 \
	$(RYGEL_COMMON_SERVER_PLUGIN_VALAFLAGS)

librygel_media_export_la_LIBADD = \
	$(RYGEL_COMMON_SERVER_LIBS) \
	$(LIBGIO_LIBS) \
	$(LIBGUPNP_DLNA_LIBS) \
	$(GSTREAMER_TAG_LIBS) \
	$(GSTREAMER_APP_LIBS) \
	$(LIBSQLITE3_LIBS) \
	$(COLLATION_LIBS)

librygel_media_export_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)

