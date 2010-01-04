plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-gst-launch.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
		$(LIBGUPNP_AV_CFLAGS) \
		$(LIBDBUS_GLIB_CFLAGS) \
		$(GEE_CFLAGS) \
		$(LIBGSTREAMER_CFLAGS) \
		-I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"' \
		-DSYS_CONFIG_DIR='"$(sysconfdir)"'

librygel_gst_launch_la_SOURCES = rygel-gst-launch-plugin.vala \
				rygel-gst-launch-root-container.vala \
				rygel-gst-launch-content-dir.vala \
				rygel-gst-launch-item.vala

librygel_gst_launch_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
			     --pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
			     --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
			     --pkg dbus-glib-1 --pkg gee-1.0 \
			     --pkg gstreamer-0.10 -g

librygel_gst_launch_la_LIBADD = $(LIBGUPNP_LIBS) \
     			       $(LIBGUPNP_AV_LIBS) \
     			       $(LIBDBUS_GLIB_LIBS) \
     			       $(LIBGSTREAMER_LIBS) \
     			       $(GEE_LIBS)

librygel_gst_launch_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
