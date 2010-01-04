if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-gst-renderer.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
            $(LIBGUPNP_AV_CFLAGS) \
            $(GEE_CFLAGS) \
            $(LIBDBUS_GLIB_CFLAGS) \
            $(LIBGSTREAMER_CFLAGS) \
            -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"'

librygel_gst_renderer_la_SOURCES = rygel-gst-connection-manager.vala \
				   rygel-gst-rendering-control.vala \
				   rygel-gst-av-transport.vala \
				   rygel-gst-player.vala \
				   rygel-gst-changelog.vala \
				   rygel-gst-plugin.vala

librygel_gst_renderer_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
                     	             --vapidir=$(srcdir) \
				     --pkg rygel-1.0 --pkg cstuff \
				     --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
				     --pkg gee-1.0 --pkg gstreamer-0.10 -g

librygel_gst_renderer_la_LIBADD = $(LIBGUPNP_LIBS) \
                    	          $(LIBGUPNP_AV_LIBS) \
				  $(LIBGSTREAMER_LIBS) \
				  $(LIBDBUS_GLIB_LIBS) \
				  $(GEE_LIBS)
librygel_gst_renderer_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
