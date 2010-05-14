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

AM_VALAFLAGS = --disable-warnings --thread \
	       --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
               --pkg gconf-2.0 --pkg gstreamer-0.10 \
               --pkg gio-2.0 --pkg gee-1.0 -g

check_PROGRAMS = rygel-http-item-uri-test \
		 rygel-live-response-test \
		 rygel-seekable-response-test \
		 rygel-http-byte-seek-test \
		 rygel-http-time-seek-test

TESTS = $(check_PROGRAMS)

rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala

rygel_live_response_test_SOURCES = rygel-live-response-test.vala \
				   rygel-live-response.vala \
                                   rygel-http-response_live-response.vala \
                                   rygel-http-response-test_live-response.vala \
				   rygel-state-machine_live-response.vala \
				   rygel-http-seek_live-response.vala \
				   rygel-gst-utils.vala

rygel_seekable_response_test_SOURCES = \
				   rygel-seekable-response-test.vala \
				   rygel-seekable-response.vala \
                                   rygel-http-response-test_seekable-response.vala \
				   rygel-http-response_seekable-response.vala \
				   rygel-state-machine_seekable-response.vala

rygel_http_byte_seek_test_SOURCES = rygel-http-byte-seek-test.vala \
				    rygel-http-byte-seek.vala \
				    rygel-http-seek.vala

rygel_http_time_seek_test_SOURCES = rygel-http-time-seek-test.vala \
				    rygel-http-time-seek.vala \
				    rygel-http-seek_time-seek.vala
