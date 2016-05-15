if UNINSTALLED
MX_EXTRACT_PATH=$(abs_builddir)/mx-extract
else
MX_EXTRACT_PATH=$(pkglibexecdir)/mx-extract
endif

include $(top_srcdir)/common.am

## Extraction helper
pkglibexec_PROGRAMS = mx-extract
mx_extract_SOURCES = \
	constants.vala \
	rygel-media-export-extract.vala \
	rygel-media-export-dvd-parser.vala \
	rygel-media-export-playlist-extractor.vala \
	rygel-media-export-image-extractor.vala \
	rygel-media-export-extractor.vala \
	rygel-media-export-generic-extractor.vala

mx_extract_VALAFLAGS = \
	--enable-experimental \
	--pkg posix \
	--pkg gio-unix-2.0 \
	--pkg gdk-pixbuf-2.0 \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

mx_extract_CFLAGS = \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"MediaExport"'

mx_extract_LDADD = \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_LIBS)

## Plugin
plugin_LTLIBRARIES = librygel-media-export.la
plugin_DATA = media-export.plugin

librygel_media_export_la_SOURCES = \
	rygel-media-export-plugin.vala \
	rygel-media-export-db-container.vala \
	rygel-media-export-sql-factory.vala \
	rygel-media-export-media-cache.vala \
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
	rygel-media-export-dvd-container.vala \
	rygel-media-export-dvd-track.vala \
	constants.vala

librygel_media_export_la_VALAFLAGS = \
	--enable-experimental \
	--internal-vapi rygel-media-export.vapi \
	--internal-header rygel-media-export-internal.h \
	--header rygel-media-export.h \
	--pkg posix \
	--pkg gio-unix-2.0 \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_DB_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_media_export_la_CFLAGS = \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_DB_CFLAGS) \
	-DMX_EXTRACT_PATH='"$(MX_EXTRACT_PATH)"' \
	-DG_LOG_DOMAIN='"MediaExport"'
librygel_media_export_la_LIBADD = \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_DB_LIBS)

librygel_media_export_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = media-export.plugin.in
