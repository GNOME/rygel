V         = @
Q         = $(V:1=)
QUIET_GEN = $(Q:@=@echo '  GEN   '$@;)

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-media-tracker.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
            $(LIBGSTREAMER_CFLAGS) \
	    $(GEE_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-media-tracker.stamp \
		rygel-media-tracker.h \
		rygel-media-tracker.c \
		rygel-tracker-root-container.h \
		rygel-tracker-root-container.c \
		rygel-tracker-category.h \
		rygel-tracker-category.c \
		rygel-tracker-video-category.h \
		rygel-tracker-video-category.c \
		rygel-tracker-music-category.h \
		rygel-tracker-music-category.c \
		rygel-tracker-image-category.h \
		rygel-tracker-image-category.c \
		rygel-tracker-search-result.h \
		rygel-tracker-search-result.c \
		rygel-tracker-get-metadata-result.h \
		rygel-tracker-get-metadata-result.c \
		rygel-tracker-item.h \
		rygel-tracker-item.c \
		rygel-tracker-video-item.h \
		rygel-tracker-video-item.c \
		rygel-tracker-music-item.h \
		rygel-tracker-music-item.c \
		rygel-tracker-image-item.h \
		rygel-tracker-image-item.c \
		rygel-tracker-plugin.h \
		rygel-tracker-plugin.c

librygel_media_tracker_la_SOURCES = rygel-media-tracker.h \
			            rygel-media-tracker.c \
				    rygel-media-tracker.vala \
				    rygel-tracker-root-container.h \
				    rygel-tracker-root-container.c \
				    rygel-tracker-root-container.vala \
				    rygel-tracker-category.h \
			            rygel-tracker-category.c \
				    rygel-tracker-category.vala \
				    rygel-tracker-video-category.h \
				    rygel-tracker-video-category.c \
				    rygel-tracker-video-category.vala \
				    rygel-tracker-music-category.h \
				    rygel-tracker-music-category.c \
				    rygel-tracker-music-category.vala \
				    rygel-tracker-image-category.h \
				    rygel-tracker-image-category.c \
				    rygel-tracker-image-category.vala \
				    rygel-tracker-search-result.h \
				    rygel-tracker-search-result.c \
				    rygel-tracker-search-result.vala \
				    rygel-tracker-get-metadata-result.h \
				    rygel-tracker-get-metadata-result.c \
				    rygel-tracker-get-metadata-result.vala \
                                    rygel-tracker-item.h \
                                    rygel-tracker-item.c \
                                    rygel-tracker-item.vala \
                                    rygel-tracker-video-item.h \
                                    rygel-tracker-video-item.c \
                                    rygel-tracker-video-item.vala \
                                    rygel-tracker-music-item.h \
                                    rygel-tracker-music-item.c \
                                    rygel-tracker-music-item.vala \
                                    rygel-tracker-image-item.h \
                                    rygel-tracker-image-item.c \
                                    rygel-tracker-image-item.vala \
				    rygel-tracker-plugin.h \
			            rygel-tracker-plugin.c \
				    rygel-tracker-plugin.vala

rygel-media-tracker.stamp: $(filter %.vala,$(librygel_media_tracker_la_SOURCES))
	$(QUIET_GEN) $(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff \
	--pkg gupnp-1.0 --pkg gupnp-av-1.0 \
        --pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10 $^
	touch $@

librygel_media_tracker_la_LIBADD = $(LIBGUPNP_LIBS) \
			       	   $(LIBGUPNP_AV_LIBS) \
				   $(LIBDBUS_GLIB_LIBS) \
	                           $(LIBGSTREAMER_LIBS) \
				   $(GEE_LIBS)
librygel_media_tracker_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
