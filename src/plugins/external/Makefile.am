plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-external.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-external-content-dir.c \
		rygel-external-container.c \
		rygel-external-item.c \
		rygel-external-plugin.c \
		rygel-external-plugin-factory.c

$(BUILT_SOURCES) : rygel-external.stamp

librygel_external_la_SOURCES = rygel-external-content-dir.c \
			       rygel-external-content-dir.vala \
			       rygel-external-container.c \
			       rygel-external-container.vala \
			       rygel-external-item.c \
			       rygel-external-item.vala \
			       rygel-external-plugin.c \
			       rygel-external-plugin.vala \
			       rygel-external-plugin-factory.c \
			       rygel-external-plugin-factory.vala

rygel-external.stamp: $(filter %.vala,$(librygel_external_la_SOURCES))
	$(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	--pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10 --pkg gconf-2.0 \
	$^
	touch $@

librygel_external_la_LIBADD = $(LIBGUPNP_LIBS) \
                              $(LIBGUPNP_AV_LIBS) \
			      $(LIBDBUS_GLIB_LIBS) \
			      $(LIBGSTREAMER_LIBS) \
			      $(GEE_LIBS) \
			      $(LIBGCONF_LIBS)
librygel_external_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-external.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-external.stamp
