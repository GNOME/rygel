if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

rygeldir = $(abs_top_builddir)/src/rygel

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGCONF_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
            $(GTK_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    $(LIBSOUP_CFLAGS) \
	    -I$(top_srcdir) -I$(rygeldir) -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

bin_PROGRAMS = rygel-preferences

BUILT_SOURCES = rygel.stamp \
		rygel-preferences.c

rygel_preferences_SOURCES = rygel-preferences.c \
                            rygel-preferences.vala

rygel.stamp: $(filter %.vala,$(rygel_preferences_SOURCES))
	$(VALAC) -C --vapidir=$(rygeldir) \
	--pkg rygel-1.0 --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
	--pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 --pkg gee-1.0 \
        --pkg gtk+-2.0 $^
	touch $@

rygel_preferences_LDADD = $(LIBGUPNP_LIBS) \
	                  $(LIBGUPNP_AV_LIBS) \
                          $(LIBGCONF_LIBS) \
                          $(LIBGSTREAMER_LIBS) \
                          $(GIO_LIBS) \
                          $(GEE_LIBS) \
                          $(UUID_LIBS) \
                          $(LIBSOUP_LIBS) \
                          $(GTK_LIBS) \
                          -L$(rygeldir) \
                          -lrygel-configuration

CLEANFILES = $(BUILT_SOURCES)
MAINTAINERCLEANFILES = Makefile.in
