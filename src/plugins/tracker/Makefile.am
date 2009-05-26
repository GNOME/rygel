plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-tracker.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
            $(LIBGSTREAMER_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-media-tracker.c \
		rygel-tracker-root-container.c \
		rygel-tracker-category.c \
		rygel-tracker-video-category.c \
		rygel-tracker-music-category.c \
		rygel-tracker-image-category.c \
		rygel-tracker-search-result.c \
		rygel-tracker-get-metadata-result.c \
		rygel-tracker-item.c \
		rygel-tracker-video-item.c \
		rygel-tracker-music-item.c \
		rygel-tracker-image-item.c \
		rygel-tracker-plugin.c \
		rygel-tracker-plugin-factory.c

$(BUILT_SOURCES) : rygel-media-tracker.stamp

librygel_media_tracker_la_SOURCES = rygel-media-tracker.c \
				    rygel-media-tracker.vala \
				    rygel-tracker-root-container.c \
				    rygel-tracker-root-container.vala \
				    rygel-tracker-category.c \
				    rygel-tracker-category.vala \
				    rygel-tracker-video-category.c \
				    rygel-tracker-video-category.vala \
				    rygel-tracker-music-category.c \
				    rygel-tracker-music-category.vala \
				    rygel-tracker-image-category.c \
				    rygel-tracker-image-category.vala \
				    rygel-tracker-search-result.c \
				    rygel-tracker-search-result.vala \
				    rygel-tracker-get-metadata-result.c \
				    rygel-tracker-get-metadata-result.vala \
				    rygel-tracker-item.c \
				    rygel-tracker-item.vala \
				    rygel-tracker-video-item.c \
				    rygel-tracker-video-item.vala \
				    rygel-tracker-music-item.c \
				    rygel-tracker-music-item.vala \
				    rygel-tracker-image-item.c \
				    rygel-tracker-image-item.vala \
				    rygel-tracker-plugin.c \
				    rygel-tracker-plugin.vala \
				    rygel-tracker-plugin-factory.c \
				    rygel-tracker-plugin-factory.vala

rygel-media-tracker.stamp: $(filter %.vala,$(librygel_media_tracker_la_SOURCES))
	$(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
        --pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10 $^
	touch $@

librygel_media_tracker_la_LIBADD = $(LIBGUPNP_LIBS) \
			       	   $(LIBGUPNP_AV_LIBS) \
				   $(LIBDBUS_GLIB_LIBS) \
	                           $(LIBGSTREAMER_LIBS) \
				   $(GEE_LIBS) \
	    			   $(LIBGCONF_LIBS)
librygel_media_tracker_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-media-tracker.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-media-tracker.stamp
