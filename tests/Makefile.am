shareddir = $(abs_top_builddir)/data

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GIO_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    $(LIBSOUP_CFLAGS) \
	    $(LIBDBUS_GLIB_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -include config.h

LDADD = $(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(UUID_LIBS) \
	$(LIBSOUP_LIBS) \
	$(LIBDBUS_GLIB_LIBS)

AM_VALAFLAGS = --thread \
	       --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
               --pkg gconf-2.0 --pkg gstreamer-0.10 \
               --pkg gio-2.0 --pkg gee-1.0 -g

check_PROGRAMS = rygel-http-item-uri-test \
		 rygel-http-response-test
TESTS = $(check_PROGRAMS)

rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala

rygel_http_response_test_SOURCES = rygel-http-response-test.vala \
				   rygel-http-response.vala \
				   rygel-state-machine.vala
