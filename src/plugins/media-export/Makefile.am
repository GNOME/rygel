if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-export.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(LIBSQLITE3_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"' \
	    -include config.h

librygel_media_export_la_SOURCES = rygel-media-export-plugin.vala \
				   rygel-media-export-database.vala \
				   rygel-media-export-db-container.vala \
				   rygel-media-export-db-object-factory.vala \
				   rygel-media-export-media-cache.vala \
				   rygel-media-export-media-cache-upgrader.vala \
				   rygel-media-export-metadata-extractor.vala \
				   rygel-media-export-null-container.vala \
				   rygel-media-export-dummy-container.vala \
				   rygel-media-export-dynamic-container.vala \
				   rygel-media-export-root-container.vala \
				   rygel-media-export-query-container.vala \
				   rygel-media-export-dbus-service.vala \
				   rygel-media-export-recursive-file-monitor.vala \
				   rygel-media-export-harvester.vala \
				   rygel-media-export-item.vala \
				   rygel-media-export-writable-container.vala \
				   rygel-media-export-object-factory.vala

librygel_media_export_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
				     --pkg dbus-glib-1 \
                                     --pkg rygel-1.0 \
                                     --pkg cstuff \
                                     --pkg gupnp-1.0 \
                                     --pkg gupnp-av-1.0 \
                                     --pkg libsoup-2.4 \
                                     --pkg gee-1.0 \
                                     --pkg libxml-2.0 \
                                     --pkg sqlite3 -g

librygel_media_export_la_LIBADD = $(LIBGUPNP_LIBS) \
				  $(LIBGUPNP_AV_LIBS) \
				  $(LIBDBUS_GLIB_LIBS) \
				  $(LIBGSTREAMER_LIBS) \
				  $(LIBSQLITE3_LIBS) \
				  $(GEE_LIBS) \
				  $(UUID_LIBS)
librygel_media_export_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
