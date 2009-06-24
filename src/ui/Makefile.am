if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

rygeldir = $(top_srcdir)/src/rygel

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
            $(GTK_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    $(LIBSOUP_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    -I$(top_srcdir) -I$(rygeldir) -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

bin_PROGRAMS = rygel-preferences

BUILT_SOURCES = rygel-preferences-dialog.c \
		rygel-preferences-section.c \
		rygel-general-pref-section.c \
		rygel-plugin-pref-section.c \
		rygel-media-export-pref-section.c \
		rygel-tracker-pref-section.c

$(BUILT_SOURCES) : rygel.stamp

rygel_preferences_SOURCES = rygel-preferences-dialog.c \
			    rygel-preferences-dialog.vala \
			    rygel-preferences-section.c \
			    rygel-preferences-section.vala \
			    rygel-general-pref-section.c \
			    rygel-general-pref-section.vala \
			    rygel-plugin-pref-section.c \
			    rygel-plugin-pref-section.vala \
			    rygel-media-export-pref-section.c \
			    rygel-media-export-pref-section.vala \
			    rygel-tracker-pref-section.c \
			    rygel-tracker-pref-section.vala

rygel.stamp: $(filter %.vala,$(rygel_preferences_SOURCES))
	$(VALAC) -C --vapidir=$(rygeldir) \
	--pkg rygel-1.0 --pkg cstuff --pkg gupnp-1.0 --pkg gupnp-av-1.0 \
	--pkg dbus-glib-1 --pkg gconf-2.0 --pkg gstreamer-0.10 \
	--pkg gio-2.0 --pkg gee-1.0 --pkg gtk+-2.0 $^
	touch $@

rygel_preferences_LDADD = $(LIBGUPNP_LIBS) \
	                  $(LIBGUPNP_AV_LIBS) \
                          $(LIBGSTREAMER_LIBS) \
                          $(GIO_LIBS) \
                          $(GEE_LIBS) \
                          $(UUID_LIBS) \
                          $(LIBSOUP_LIBS) \
                          $(GTK_LIBS) \
	    		  $(LIBDBUS_GLIB_LIBS) \
                          -L$(abs_top_builddir)/src/rygel \
                          -lrygel-configuration
rygel_preferences_LDFLAGS = -export-dynamic

CLEANFILES = rygel.stamp
MAINTAINERCLEANFILES = Makefile.in $(BUILT_SOURCES)
EXTRA_DIST = $(BUILT_SOURCES) rygel.stamp
