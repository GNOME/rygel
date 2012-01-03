shareddir = $(abs_top_builddir)/data

AM_CFLAGS = $(LIBGUPNP_CFLAGS) \
	    $(LIBGUPNP_AV_CFLAGS) \
	    $(LIBGSTREAMER_CFLAGS) \
	    $(GSTREAMER_BASE_CFLAGS) \
	    $(GST_PBU_CFLAGS) \
	    $(GIO_CFLAGS) \
	    $(GEE_CFLAGS) \
	    $(UUID_CFLAGS) \
	    $(LIBSOUP_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -include config.h  -DG_LOG_DOMAIN='"Rygel"' \
	    $(COVERAGE_CFLAGS)

LDADD = $(LIBGUPNP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(GSTREAMER_BASE_LIBS) \
	$(GST_PBU_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(UUID_LIBS) \
	$(LIBSOUP_LIBS) \
	$(COVERAGE_LIBS)

AM_VALAFLAGS = --disable-warnings --thread \
	       --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
               --pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gstreamer-base-0.10 \
               --pkg gio-2.0 --pkg gee-1.0 --pkg gstreamer-pbutils-0.10 \
	       $(COVERAGE_VALAFLAGS)

check_PROGRAMS = rygel-http-item-uri-test \
		 rygel-http-response-test \
		 rygel-http-byte-seek-test \
		 rygel-http-time-seek-test \
		 rygel-http-get-test \
		 rygel-album-art-spec-test \
		 rygel-http-post-test

TESTS = $(check_PROGRAMS)

rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala

rygel_http_response_test_SOURCES = rygel-http-response-test.vala \
				   rygel-http-response.vala \
				   rygel-state-machine_http-response.vala \
				   rygel-http-gst-sink.vala \
				   rygel-gst-utils.vala

rygel_http_byte_seek_test_SOURCES = rygel-http-byte-seek-test.vala \
				    rygel-http-byte-seek.vala \
				    rygel-http-seek.vala

rygel_http_time_seek_test_SOURCES = rygel-http-time-seek-test.vala \
				    rygel-http-time-seek.vala \
				    rygel-http-seek_time-seek.vala

rygel_http_get_test_SOURCES = rygel-http-get-test.vala \
			      rygel-http-get.vala \
			      rygel-http-request_http-get.vala \
			      rygel-http-item-uri_http-get.vala \
			      rygel-state-machine_http-get.vala \
			      rygel-http-time-seek_http-get.vala \
			      rygel-http-byte-seek_http-get.vala \
			      rygel-http-seek_http-get.vala

rygel_http_post_test_SOURCES = rygel-http-post-test.vala \
			       rygel-http-post.vala \
			       rygel-http-request_http-post.vala \
			       rygel-http-item-uri_http-post.vala \
			       rygel-state-machine_http-post.vala

rygel_album_art_spec_test_SOURCES = rygel-album-art-spec-test.vala \
			       rygel-media-art-store.vala \
				   ../src/rygel/rygel-thumbnail.vala \
				   ../src/rygel/rygel-icon-info.vala

if ALWAYS_TEST
all-local: check
endif

if ENABLE_COVERAGE
coverage: check
	$(LCOV) --directory $(srcdir) --capture \
		--output-file $(top_builddir)/rygel.info
	$(LCOV) --directory $(srcdir) --output-file $(top_builddir)/rygel.info \
		--remove $(top_builddir)/rygel.info "*.c" "*.h" "*.vapi"
	rm -rf $(top_builddir)/coverage
	$(mkdir_p) $(top_builddir)/coverage
	$(GENHTML) --title "@PACKAGE_STRING@" \
		--output-directory $(top_builddir)/coverage \
		$(top_builddir)/rygel.info
endif
