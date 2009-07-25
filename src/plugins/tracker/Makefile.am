plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-tracker.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GEE_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

librygel_media_tracker_la_SOURCES = \
				    rygel-media-tracker.vala \
				    rygel-tracker-root-container.vala \
				    rygel-tracker-category.vala \
				    rygel-tracker-video-category.vala \
				    rygel-tracker-music-category.vala \
				    rygel-tracker-image-category.vala \
				    rygel-tracker-search-result.vala \
				    rygel-tracker-get-metadata-result.vala \
				    rygel-tracker-item.vala \
				    rygel-tracker-video-item.vala \
				    rygel-tracker-music-item.vala \
				    rygel-tracker-image-item.vala \
				    rygel-tracker-plugin.vala \
				    rygel-tracker-plugin-factory.vala

librygel_media_tracker_la_VALAFLAGS = \
	--vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	--pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10

librygel_media_tracker_la_LIBADD = $(LIBGUPNP_LIBS) \
				   $(LIBGUPNP_AV_LIBS) \
				   $(LIBDBUS_GLIB_LIBS) \
				   $(LIBGSTREAMER_LIBS) \
				   $(GEE_LIBS)
librygel_media_tracker_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
