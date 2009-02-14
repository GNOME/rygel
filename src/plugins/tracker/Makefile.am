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
		rygel-tracker-container.h \
		rygel-tracker-container.c \
		rygel-tracker-video-container.h \
		rygel-tracker-video-container.c \
		rygel-tracker-music-container.h \
		rygel-tracker-music-container.c \
		rygel-tracker-image-container.h \
		rygel-tracker-image-container.c \
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
				    rygel-tracker-container.h \
			            rygel-tracker-container.c \
				    rygel-tracker-container.vala \
				    rygel-tracker-video-container.h \
				    rygel-tracker-video-container.c \
				    rygel-tracker-video-container.vala \
				    rygel-tracker-music-container.h \
				    rygel-tracker-music-container.c \
				    rygel-tracker-music-container.vala \
				    rygel-tracker-image-container.h \
				    rygel-tracker-image-container.c \
				    rygel-tracker-image-container.vala \
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
	$(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
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
