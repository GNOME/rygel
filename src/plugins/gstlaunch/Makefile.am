plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-gstlaunch.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
		$(LIBGUPNP_AV_CFLAGS) \
		$(LIBDBUS_GLIB_CFLAGS) \
		$(GEE_CFLAGS) \
		$(LIBGSTREAMER_CFLAGS) \
		$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"' \
		-DSYS_CONFIG_DIR='"$(sysconfdir)"'

librygel_gstlaunch_la_SOURCES = rygel-gstlaunch-plugin.vala \
				rygel-gstlaunch-root-container.vala \
				rygel-gstlaunch-content-dir.vala \
				rygel-gstlaunch-item.vala

librygel_gstlaunch_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
			     --pkg rygel-1.0 --pkg cstuff --pkg gconf-2.0 \
			     --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
			     --pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10

librygel_gstlaunch_la_LIBADD = $(LIBGUPNP_LIBS) \
     			       $(LIBGUPNP_AV_LIBS) \
     			       $(LIBDBUS_GLIB_LIBS) \
     			       $(LIBGSTREAMER_LIBS) \
     			       $(GEE_LIBS)

librygel_gstlaunch_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
