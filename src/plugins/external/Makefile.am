if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/rygel
endif

plugindir = $(libdir)/rygel-1.0

plugin_LTLIBRARIES = librygel-external.la

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(UUID_FLAGS) \
	    -I$(top_srcdir)/src/rygel -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

librygel_external_la_SOURCES = rygel-external-container.vala \
			       rygel-external-dummy-container.vala \
			       rygel-external-item-factory.vala \
			       rygel-external-album-art-factory.vala \
			       rygel-external-thumbnail-factory.vala \
			       rygel-external-plugin.vala \
			       rygel-external-interfaces.vala \
			       rygel-external-plugin-factory.vala \
			       rygel-external-icon-factory.vala

rygel-external.stamp: $(librygel_external_la_VALASOURCES)
librygel_external_la_VALAFLAGS = --vapidir=$(top_srcdir)/src/rygel \
				 --pkg rygel-1.0 --pkg gupnp-1.0 \
				 --pkg gupnp-av-1.0 --pkg gee-1.0 \
				 --pkg gstreamer-0.10 --pkg gconf-2.0 -g

librygel_external_la_LIBADD = $(LIBGUPNP_LIBS) \
                              $(LIBGUPNP_AV_LIBS) \
			      $(LIBGSTREAMER_LIBS) \
			      $(GEE_LIBS) \
			      $(UUID_LIBS)
librygel_external_la_LDFLAGS = -shared -fPIC -module -avoid-version

MAINTAINERCLEANFILES = Makefile.in

vala-clean:
	rm -f `find . -name "*.stamp"`
