if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-external.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"'

librygel_external_la_SOURCES = rygel-external-content-dir.vala \
			       rygel-external-container.vala \
			       rygel-external-item-factory.vala \
			       rygel-external-thumbnail-factory.vala \
			       rygel-external-plugin.vala \
			       rygel-external-interfaces.vala \
			       rygel-external-plugin-factory.vala \
			       rygel-external-icon-factory.vala

rygel-external.stamp: $(librygel_external_la_VALASOURCES)
librygel_external_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel -g \
				 --pkg rygel-1.0 --pkg cstuff --pkg gupnp-1.0 \
				 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
				 --pkg gee-1.0 --pkg gstreamer-0.10 \
				 --pkg gconf-2.0

librygel_external_la_LIBADD = $(LIBGUPNP_LIBS) \
                              $(LIBGUPNP_AV_LIBS) \
			      $(LIBDBUS_GLIB_LIBS) \
			      $(LIBGSTREAMER_LIBS) \
			      $(GEE_LIBS)
librygel_external_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in
