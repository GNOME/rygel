if UNINSTALLED
shareddir = $(abs_top_builddir)/data
icondir = $(shareddir)/icons/32x32
else
shareddir = $(datadir)/rygel
icondir = $(datadir)/icons/hicolor/32x32/apps
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
	    -I$(top_srcdir) -I$(rygeldir) -DDATA_DIR='"$(shareddir)"' \
	    -DSMALL_ICON_DIR='"$(icondir)"' -include config.h \
	    -DLOCALEDIR=\""$(datadir)/locale"\"

bin_PROGRAMS = rygel-preferences

rygel_preferences_SOURCES = \
			    rygel-preferences-dialog.vala \
			    rygel-preferences-section.vala \
			    rygel-general-pref-section.vala \
			    rygel-plugin-pref-section.vala \
			    rygel-media-export-pref-section.vala \
			    rygel-tracker-pref-section.vala

rygel.stamp: $(rygel_preferences_VALASOURCES)
rygel_preferences_VALAFLAGS = \
	--vapidir=$(rygeldir) --thread \
	--pkg rygel-1.0 --pkg rygel-build-config --pkg gupnp-1.0 \
	--pkg gupnp-av-1.0 --pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gio-2.0 \
	--pkg gee-1.0 --pkg gtk+-$(GTK_VAPI_VERSION) -g

rygel_preferences_LDADD = \
		$(abs_top_builddir)/src/rygel/librygel-configuration.a \
		$(LIBGUPNP_LIBS) \
		$(LIBGUPNP_AV_LIBS) \
		$(LIBGSTREAMER_LIBS) \
		$(GIO_LIBS) \
		$(GEE_LIBS) \
		$(UUID_LIBS) \
		$(LIBSOUP_LIBS) \
		$(GTK_LIBS)
rygel_preferences_LDFLAGS = -export-dynamic

MAINTAINERCLEANFILES = Makefile.in
