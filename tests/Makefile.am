include ../common.am

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

# Define the most commonly-used flags,
# to avoid repetition:
test_valaflags = \
	--pkg gee-0.8
	$(RYGEL_DEBUG_VALAFLAGS) \
	$(COVERAGE_VALAFLAGS)
test_cflags = \
	$(GEE_CFLAGS)
test_libs = \
	$(LIBGIO_LIBS) \
	$(GEE_LIBS) \
        $(COVERAGE_LIBS)

# This is for tests that link to librygel-server,
# instead of compiling its source files directly:
test_server_valaflags = \
	$(test_valaflags) \
	--vapidir $(top_builddir)/src/librygel-core \
	--pkg rygel-core-2.0 \
	--vapidir $(top_builddir)/src/librygel-server \
	--pkg rygel-server-2.0
test_server_cflags = \
	$(test_cflags) \
	-I$(top_builddir)/src/librygel-server \
	-I$(top_srcdir)/src/librygel-server \
	-I$(top_builddir)/src/librygel-core \
	-I$(top_srcdir)/src/librygel-core \
	$(LIBGUPNP_AV_CFLAGS)
test_server_libs = \
	$(test_libs) \
	$(top_builddir)/src/librygel-server/librygel-server-2.0.la \
	$(top_builddir)/src/librygel-core/librygel-core-2.0.la \
	$(LIBGUPNP_AV_LIBS)
	
# Note that the non-test sources here are symlinked from their
# various source directories.
# TODO: Mention their relative paths instead, to make this clearer?
rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala
rygel_http_item_uri_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-1.0
rygel_http_item_uri_test_LDADD = $(test_libs) \
	$(LIBGUPNP_AV_LIBS)

rygel_http_response_test_SOURCES = rygel-http-response-test.vala \
				   rygel-http-response.vala \
				   rygel-state-machine_http-response.vala \
				   rygel-data-source_http-response.vala \
				   rygel-data-sink_http-response.vala
rygel_http_response_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-1.0
rygel_http_response_test_LDADD = $(test_libs) \
	$(LIBGUPNP_LIBS)

rygel_http_byte_seek_test_SOURCES = rygel-http-byte-seek-test.vala \
				    rygel-http-byte-seek.vala \
				    rygel-http-seek.vala
rygel_http_byte_seek_test_VALAFLAGS = $(test_valaflags) \
	--pkg libsoup-2.4
rygel_http_byte_seek_test_LDADD = $(test_libs) \
	$(LIBSOUP_LIBS)

rygel_http_time_seek_test_SOURCES = rygel-http-time-seek-test.vala \
				    rygel-http-time-seek.vala \
				    rygel-http-seek_time-seek.vala
rygel_http_time_seek_test_VALAFLAGS = $(test_valaflags) \
	--pkg libsoup-2.4
rygel_http_time_seek_test_LDADD = $(test_libs) \
	$(LIBSOUP_LIBS)

rygel_http_get_test_SOURCES = rygel-http-get-test.vala \
			      rygel-http-get.vala \
			      rygel-http-request_http-get.vala \
			      rygel-http-item-uri_http-get.vala \
			      rygel-state-machine_http-get.vala \
			      rygel-http-time-seek_http-get.vala \
			      rygel-http-byte-seek_http-get.vala \
			      rygel-http-seek_http-get.vala
rygel_http_get_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_http_get_test_LDADD = $(test_libs) \
	$(LIBGUPNP_AV_LIBS)

rygel_http_post_test_SOURCES = rygel-http-post-test.vala \
			       rygel-http-post.vala \
			       rygel-http-request_http-post.vala \
			       rygel-http-item-uri_http-post.vala \
			       rygel-state-machine_http-post.vala
rygel_http_post_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_http_post_test_LDADD = $(test_libs) \
	$(LIBGUPNP_AV_LIBS)

rygel_album_art_spec_test_SOURCES = rygel-album-art-spec-test.vala \
			       rygel-media-art-store.vala \
				   rygel-thumbnail.vala \
				   rygel-icon-info.vala
rygel_album_art_spec_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_album_art_spec_test_LDADD = $(test_libs) \
	$(LIBGUPNP_AV_LIBS)

rygel_searchable_container_test_SOURCES = \
	rygel-searchable-container.vala \
	rygel-searchable-container-test.vala
rygel_searchable_container_test_VALAFLAGS = \
	$(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_searchable_container_test_LDADD = $(test_libs) \
	$(LIBGUPNP_AV_LIBS)

rygel_item_creator_test_SOURCES = rygel-item-creator-test.vala \
				  rygel-item-creator.vala \
				  rygel-data-source.vala \
				  rygel-dlna-profile.vala \
				  rygel-http-seek_item-creator.vala \
				  rygel-state-machine_item-creator.vala \
				  rygel-relational-expression.vala \
				  rygel-search-expression.vala \
				  rygel-media-engine.vala \
				  rygel-serializer_item-creator.vala
rygel_item_creator_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-av-1.0 \
	--vapidir $(top_srcdir)/src/librygel-core \
	--pkg uuid
rygel_item_creator_test_LDADD = $(test_libs) \
	$(LIBGUPNP_AV_LIBS)

rygel_user_config_test_SOURCES = rygel-configuration.vala \
				 rygel-user-config.vala \
				 rygel-user-config-test.vala
rygel_user_config_test_VALAFLAGS = \
	$(test_valaflags) \
	--vapidir $(top_builddir)/src/librygel-core \
	--pkg rygel-build-config \
	--pkg gio-2.0
rygel_user_config_test_LDADD = \
	$(test_libs)
rygel_user_config_test_CFLAGS =  \
	$(test_cflags) \
	-DSYS_CONFIG_DIR='"$(sysconfigdir)"'

rygel_regression_SOURCES = \
	rygel-regression.vala
rygel_regression_VALAFLAGS = \
	$(test_server_valaflags) \
	--pkg gio-2.0
rygel_regression_CFLAGS = \
	$(test_server_cflags)
rygel_regression_LDADD = \
	$(test_server_libs)

rygel_media_engine_test_SOURCES = \
	rygel-media-engine-test.vala
rygel_media_engine_test_VALAFLAGS = \
	$(test_server_valaflags)\
        --pkg gmodule-2.0
rygel_media_engine_test_CFLAGS = \
	-DTEST_DATA_FOLDER='"$(abs_srcdir)/data"' \
	-DTEST_ENGINE_PATH='"$(abs_top_builddir)/src/media-engines"' \
	-DBUILT_ENGINES='"@BUILT_ENGINES@"' \
	$(test_server_cflags)
rygel_media_engine_test_LDADD = \
	$(test_server_libs)

if HAVE_GSTREAMER
check_PROGRAMS += \
	rygel-playbin-renderer-test \
	rygel-environment-test

librygel_renderer_gst_valaflags = \
	$(LIBRYGEL_RENDERER_GST_VALAFLAGS_PKG) \
	$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
	
rygel_playbin_renderer_test_SOURCES = rygel-playbin-renderer-test.vala
rygel_playbin_renderer_test_VALAFLAGS = \
	--pkg rygel-renderer-gst-2.0 \
	--vapidir $(top_srcdir)/src/librygel-renderer-gst \
	$(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)
rygel_playbin_renderer_test_CFLAGS = \
	$(GEE_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(LIBGUPNP_CFLAGS) \
	-I$(top_builddir)/src/librygel-renderer \
	-I$(top_srcdir)/src/librygel-renderer \
	-I$(top_builddir)/src/librygel-renderer-gst \
	-I$(top_srcdir)/src/librygel-renderer-gst \
	-I$(top_builddir)/src/librygel-core \
	-I$(top_srcdir)/src/librygel-core
rygel_playbin_renderer_test_LDADD = \
	$(test_libs) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGUPNP_LIBS) \
	$(top_builddir)/src/librygel-renderer/librygel-renderer-2.0.la \
	$(top_builddir)/src/librygel-renderer-gst/librygel-renderer-gst-2.0.la \
	$(top_builddir)/src/librygel-core/librygel-core-2.0.la

rygel_environment_test_SOURCES = rygel-environment-test.vala
rygel_environment_test_CFLAGS =  \
	$(GEE_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS)
rygel_environment_test_LDADD = \
	$(test_libs) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGUPNP_LIBS)
rygel_environment_test_VALAFLAGS = \
	--pkg rygel-renderer-gst-2.0 \
	--vapidir $(top_srcdir)/src/librygel-renderer-gst \
	$(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)
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
