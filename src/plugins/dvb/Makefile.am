plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-dvb.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(datadir)"'

BUILT_SOURCES = rygel-dvb-content-dir.c \
		rygel-dvb-root-container.c \
		rygel-dvb-channel-group.c \
		rygel-dvb-channel.c \
		rygel-dvb-plugin.c \
		rygel-dvb-plugin-factory.c

$(BUILT_SOURCES) : rygel-dvb.stamp

librygel_dvb_la_SOURCES = rygel-dvb-content-dir.c \
			  rygel-dvb-content-dir.vala \
			  rygel-dvb-root-container.c \
			  rygel-dvb-root-container.vala \
			  rygel-dvb-channel-group.c \
			  rygel-dvb-channel-group.vala \
			  rygel-dvb-channel.c \
			  rygel-dvb-channel.vala \
			  rygel-dvb-plugin.c \
			  rygel-dvb-plugin.vala \
			  rygel-dvb-plugin-factory.c \
			  rygel-dvb-plugin-factory.vala

rygel-dvb.stamp: $(filter %.vala,$(librygel_dvb_la_SOURCES))
	$(VALAC) -C --vapidir=$(top_srcdir)/src/rygel \
	--pkg rygel-1.0 --pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	--pkg dbus-glib-1 --pkg gee-1.0 --pkg gstreamer-0.10 --pkg gconf-2.0 \
	$^
	touch $@

librygel_dvb_la_LIBADD = $(LIBGUPNP_LIBS) \
                         $(LIBGUPNP_AV_LIBS) \
                         $(LIBDBUS_GLIB_LIBS) \
	                 $(LIBGSTREAMER_LIBS) \
                         $(GEE_LIBS) \
	    		 $(LIBGCONF_LIBS)
librygel_dvb_la_LDFLAGS = -shared -fPIC -module -avoid-version

CLEANFILES = $(BUILT_SOURCES) rygel-dvb.stamp
MAINTAINERCLEANFILES = Makefile.in
EXTRA_DIST = $(BUILT_SOURCES) rygel-dvb.stamp
