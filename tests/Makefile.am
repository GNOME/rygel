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
	    $(LIBGUPNP_DLNA_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"' \
	    -include config.h  -DG_LOG_DOMAIN='"Rygel"' \
	    $(COVERAGE_CFLAGS)

LDADD = $(LIBGUPNP_LIBS) \
	$(LIBGSSDP_LIBS) \
	$(LIBGUPNP_AV_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(GSTREAMER_BASE_LIBS) \
	$(GST_PBU_LIBS) \
	$(LIBGIO_LIBS) \
	$(GEE_LIBS) \
	$(UUID_LIBS) \
	$(LIBSOUP_LIBS) \
	$(LIBGUPNP_DLNA_LIBS) \
	$(COVERAGE_LIBS)

AM_VALAFLAGS = --disable-warnings \
	       --pkg gupnp-1.0 --pkg gupnp-av-1.0 --pkg dbus-glib-1 \
               --pkg gconf-2.0 --pkg gstreamer-0.10 --pkg gstreamer-base-0.10 \
               --pkg gio-2.0 --pkg gee-1.0 --pkg gstreamer-pbutils-0.10 \
               --pkg uuid --vapidir=$(top_srcdir)/src/librygel-core -g \
	       $(COVERAGE_VALAFLAGS)

check_PROGRAMS = rygel-http-item-uri-test \
		 rygel-http-response-test \
		 rygel-http-byte-seek-test \
		 rygel-http-time-seek-test \
		 rygel-http-get-test \
		 rygel-album-art-spec-test \
		 rygel-http-post-test \
		 rygel-searchable-container-test \
		 rygel-item-creator-test \
		 rygel-user-config-test \
		 rygel-regression \
		 rygel-media-engine-test

TESTS = $(check_PROGRAMS)

EXTRA_DIST = $(srcdir)/data/test-data.dat

rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala

rygel_http_response_test_SOURCES = rygel-http-response-test.vala \
				   rygel-http-response.vala \
				   rygel-state-machine_http-response.vala \
				   rygel-data-source_http-response.vala \
				   rygel-data-sink_http-response.vala

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
				   rygel-thumbnail.vala \
				   rygel-icon-info.vala

rygel_searchable_container_test_SOURCES = \
	rygel-searchable-container.vala \
	rygel-searchable-container-test.vala

rygel_item_creator_test_SOURCES = rygel-item-creator-test.vala \
				  rygel-item-creator.vala \
				  rygel-data-source.vala \
				  rygel-http-seek_item-creator.vala \
				  rygel-state-machine_item-creator.vala \
				  rygel-relational-expression.vala \
				  rygel-search-expression.vala \
				  rygel-media-engine.vala

rygel_user_config_test_SOURCES = rygel-configuration.vala \
				 rygel-user-config.vala \
				 rygel-user-config-test.vala

rygel_user_config_test_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--pkg rygel-build-config

rygel_user_config_test_CFLAGS = \
	$(AM_CFLAGS) \
	-DSYS_CONFIG_DIR='"$(sysconfigdir)"'

rygel_regression_SOURCES = \
	rygel-regression.vala

rygel_regression_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--pkg rygel-server-2.0 \
	--pkg rygel-core-2.0 \
	--vapidir $(top_builddir)/src/librygel-server \
	--vapidir $(top_builddir)/src/librygel-core

rygel_regression_CFLAGS = \
	$(AM_CFLAGS) \
	-I$(top_builddir)/src/librygel-server \
	-I$(top_srcdir)/src/librygel-server \
	-I$(top_builddir)/src/librygel-core \
	-I$(top_srcdir)/src/librygel-core

rygel_regression_LDADD = \
	$(LDADD) \
	$(top_builddir)/src/librygel-server/librygel-server-2.0.la \
	$(top_builddir)/src/librygel-core/librygel-core-2.0.la

rygel_media_engine_test_SOURCES = \
	rygel-media-engine-test.vala

rygel_media_engine_test_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--pkg rygel-server-2.0 \
	--pkg rygel-core-2.0 \
	--vapidir $(top_builddir)/src/librygel-server \
	--vapidir $(top_builddir)/src/librygel-core

rygel_media_engine_test_CFLAGS = \
	$(AM_CFLAGS) \
	-DTEST_DATA_FOLDER='"$(abs_srcdir)/data"' \
	-DTEST_ENGINE_PATH='"$(abs_top_builddir)/src/media-engines"' \
	-DBUILT_ENGINES='"@BUILT_ENGINES@"' \
	-I$(top_builddir)/src/librygel-server \
	-I$(top_srcdir)/src/librygel-server \
	-I$(top_builddir)/src/librygel-core \
	-I$(top_srcdir)/src/librygel-core

rygel_media_engine_test_LDADD = \
	$(LDADD) \
	$(top_builddir)/src/librygel-server/librygel-server-2.0.la \
	$(top_builddir)/src/librygel-core/librygel-core-2.0.la

if HAVE_GSTREAMER
check_PROGRAMS += \
	rygel-playbin-renderer-test \
	rygel-environment-test

rygel_playbin_renderer_test_SOURCES = rygel-playbin-renderer-test.vala

rygel_playbin_renderer_test_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--pkg rygel-renderer-gst-2.0 \
	--pkg rygel-renderer-2.0 \
	--pkg rygel-core-2.0 \
	--vapidir $(top_builddir)/src/librygel-renderer \
	--vapidir $(top_builddir)/src/librygel-renderer-gst \
	--vapidir $(top_builddir)/src/librygel-core

rygel_playbin_renderer_test_LDADD = \
	$(top_builddir)/src/librygel-renderer/librygel-renderer-2.0.la \
	$(top_builddir)/src/librygel-renderer-gst/librygel-renderer-gst-2.0.la \
	$(top_builddir)/src/librygel-core/librygel-core-2.0.la \
	$(LDADD)

rygel_playbin_renderer_test_CFLAGS = \
	$(AM_CFLAGS) \
	-I$(top_builddir)/src/librygel-renderer \
	-I$(top_srcdir)/src/librygel-renderer \
	-I$(top_builddir)/src/librygel-renderer-gst \
	-I$(top_srcdir)/src/librygel-renderer-gst \
	-I$(top_builddir)/src/librygel-core \
	-I$(top_srcdir)/src/librygel-core

rygel_environment_test_SOURCES = rygel-environment-test.vala
rygel_environment_test_CFLAGS = $(AM_CFLAGS)
rygel_environment_test_LDADD = $(LDADD)
rygel_environment_test_VALAFLAGS = $(AM_VALAFLAGS) --pkg gstreamer-0.10
endif

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
