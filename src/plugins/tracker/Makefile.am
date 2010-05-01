plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-tracker.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"' \
	    -include config.h

librygel_media_tracker_la_SOURCES = \
				    rygel-media-tracker.vala \
				    rygel-tracker-root-container.vala \
				    rygel-tracker-category-container.vala \
				    rygel-tracker-music.vala \
				    rygel-tracker-videos.vala \
				    rygel-tracker-pictures.vala \
				    rygel-tracker-metadata-values.vala \
				    rygel-tracker-tags.vala \
				    rygel-tracker-years.vala \
				    rygel-tracker-search-container.vala \
				    rygel-tracker-category-all-container.vala \
				    rygel-tracker-query.vala \
				    rygel-tracker-selection-query.vala \
				    rygel-tracker-insertion-query.vala \
				    rygel-tracker-query-triplet.vala \
				    rygel-tracker-query-triplets.vala \
				    rygel-tracker-item-factory.vala \
				    rygel-tracker-item-creation.vala \
				    rygel-tracker-video-item-factory.vala \
				    rygel-tracker-music-item-factory.vala \
				    rygel-tracker-picture-item-factory.vala \
				    rygel-tracker-plugin.vala \
				    rygel-tracker-plugin-factory.vala \
				    rygel-tracker-interfaces.vala

librygel_media_tracker_la_VALAFLAGS = \
	--vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	--pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10 -g

librygel_media_tracker_la_LIBADD = $(LIBGUPNP_LIBS) \
				   $(LIBGUPNP_AV_LIBS) \
				   $(LIBDBUS_GLIB_LIBS) \
				   $(LIBGSTREAMER_LIBS) \
				   $(GEE_LIBS) \
				   $(UUID_LIBS)
librygel_media_tracker_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
