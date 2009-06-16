if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-gst.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(GTK_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"'

BUILT_SOURCES = rygel-gst-connection-manager.c \
		rygel-gst-rendering-control.c \
		rygel-gst-av-transport.c \
		rygel-gst-video-window.c \
		rygel-gst-changelog.c \
		rygel-gst-plugin.c

$(BUILT_SOURCES) : rygel-gst.stamp

librygel_gst_la_SOURCES = rygel-gst-connection-manager.c \
			  rygel-gst-connection-manager.vala \
			  rygel-gst-rendering-control.c \
			  rygel-gst-rendering-control.vala \
			  rygel-gst-av-transport.c \
			  rygel-gst-av-transport.vala \
			  rygel-gst-video-window.c \
			  rygel-gst-video-window.vala \
			  rygel-gst-changelog.c \
			  rygel-gst-changelog.vala \
			  rygel-gst-plugin.c \
			  rygel-gst-plugin.vala \
			  owl-video-widget.c \
			  owl-video-widget.h

rygel-gst.stamp: $(filter %.vala,$(librygel_gst_la_SOURCES))
	$(VALAC) -C --vapidir=$(srcdir) --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	--pkg owl-video-widget --pkg gee-1.0 --pkg gstreamer-0.10 \
	--pkg gconf-2.0 --pkg gtk+-2.0 \
	$^
	touch $@

librygel_gst_la_LIBADD = $(LIBGUPNP_LIBS) \
                         $(LIBGUPNP_AV_LIBS) \
	                 $(LIBGSTREAMER_LIBS) \
                         $(GEE_LIBS) \
                         $(GTK_LIBS) \
	    		 $(LIBGCONF_LIBS)
librygel_gst_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-gst.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-gst.stamp owl-video-widget.vapi
