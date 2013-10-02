include $(top_srcdir)/common.am

check_PROGRAMS = rygel-http-item-uri-test \
		 rygel-http-response-test \
		 rygel-http-byte-seek-test \
		 rygel-http-time-seek-test \
		 rygel-http-get-test \
		 rygel-album-art-spec-test \
		 rygel-http-post-test \
		 rygel-searchable-container-test \
		 rygel-object-creator-test \
		 rygel-user-config-test \
		 rygel-regression \
		 rygel-media-engine-test

TESTS = $(check_PROGRAMS)

EXTRA_DIST = $(srcdir)/data/test-data.dat

# Define the most commonly-used flags,
# to avoid repetition:
test_valaflags = \
	$(TEST_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
test_cflags = \
	$(TEST_DEPS_CFLAGS) \
	$(RYGEL_COMMON_DEFINES_CFLAGS)
test_libs = \
	$(TEST_DEPS_LIBS) \
	$(COVERAGE_LIBS)

# This is for tests that link to librygel-server,
# instead of compiling its source files directly:
test_server_valaflags = \
	$(test_valaflags) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS)
test_server_cflags = \
	$(test_cflags) \
	$(LIBRYGEL_SERVER_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS)
test_server_libs = \
	$(test_libs) \
	$(LIBRYGEL_SERVER_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
	
# Note that the non-test sources here are symlinked from their
# various source directories.
# TODO: Mention their relative paths instead, to make this clearer?
rygel_http_item_uri_test_SOURCES = rygel-http-item-uri-test.vala \
                                   rygel-http-item-uri.vala
rygel_http_item_uri_test_VALAFLAGS = \
	$(test_valaflags)
rygel_http_item_uri_test_CFLAGS =  \
	$(test_cflags)
rygel_http_item_uri_test_LDADD = \
	$(test_libs)

rygel_http_response_test_SOURCES = rygel-http-response-test.vala \
				   rygel-http-response.vala \
				   rygel-state-machine_http-response.vala \
				   rygel-data-source_http-response.vala \
				   rygel-data-sink_http-response.vala
rygel_http_response_test_VALAFLAGS = \
	$(test_valaflags)
rygel_http_response_test_CFLAGS =  \
	$(test_cflags)
rygel_http_response_test_LDADD = \
	$(test_libs)

rygel_http_byte_seek_test_SOURCES = rygel-http-byte-seek-test.vala \
				    rygel-http-byte-seek.vala \
				    rygel-http-seek.vala
rygel_http_byte_seek_test_VALAFLAGS = \
	$(test_valaflags)
rygel_http_byte_seek_test_CFLAGS =  \
	$(test_cflags)
rygel_http_byte_seek_test_LDADD = $(test_libs)

rygel_http_time_seek_test_SOURCES = rygel-http-time-seek-test.vala \
				    rygel-http-time-seek.vala \
				    rygel-http-seek_time-seek.vala
rygel_http_time_seek_test_VALAFLAGS = \
	$(test_valaflags)
rygel_http_time_seek_test_CFLAGS =  \
	$(test_cflags)
rygel_http_time_seek_test_LDADD = \
	$(test_libs)

rygel_http_get_test_SOURCES = rygel-http-get-test.vala \
			      rygel-http-get.vala \
			      rygel-http-request_http-get.vala \
			      rygel-http-item-uri_http-get.vala \
			      rygel-state-machine_http-get.vala \
			      rygel-http-time-seek_http-get.vala \
			      rygel-http-byte-seek_http-get.vala \
			      rygel-http-seek_http-get.vala
rygel_http_get_test_VALAFLAGS = \
	$(test_valaflags)
rygel_http_get_test_CFLAGS =  \
	$(test_cflags)
rygel_http_get_test_LDADD = \
	$(test_libs)

rygel_http_post_test_SOURCES = rygel-http-post-test.vala \
			       rygel-http-post.vala \
			       rygel-http-request_http-post.vala \
			       rygel-http-item-uri_http-post.vala \
			       rygel-state-machine_http-post.vala
rygel_http_post_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_http_post_test_CFLAGS =  \
	$(test_cflags)
rygel_http_post_test_LDADD = \
	$(test_libs)

rygel_album_art_spec_test_SOURCES = rygel-album-art-spec-test.vala \
			       rygel-media-art-store.vala \
				   rygel-thumbnail.vala \
				   rygel-icon-info.vala
rygel_album_art_spec_test_VALAFLAGS = $(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_album_art_spec_test_CFLAGS =  \
	$(test_cflags)
rygel_album_art_spec_test_LDADD = \
	$(test_libs)

rygel_searchable_container_test_SOURCES = \
	rygel-searchable-container.vala \
	rygel-searchable-container-test.vala
rygel_searchable_container_test_VALAFLAGS = \
	$(test_valaflags) \
	--pkg gupnp-av-1.0
rygel_searchable_container_test_CFLAGS =  \
	$(test_cflags)
rygel_searchable_container_test_LDADD = \
	$(test_libs)

rygel_object_creator_test_SOURCES = rygel-object-creator-test.vala \
				  rygel-object-creator.vala \
				  rygel-data-source.vala \
				  rygel-dlna-profile.vala \
				  rygel-http-seek_object-creator.vala \
				  rygel-state-machine_object-creator.vala \
				  rygel-relational-expression.vala \
				  rygel-logical-expression.vala \
				  rygel-search-expression.vala \
				  rygel-search-criteria-parser.vala \
				  rygel-serializer_object-creator.vala \
				  rygel-m3u-playlist_object-creator.vala
rygel_object_creator_test_VALAFLAGS = \
	$(test_valaflags) \
	--pkg uuid
rygel_object_creator_test_CFLAGS =  \
	$(test_cflags)
rygel_object_creator_test_LDADD = \
	$(test_libs)

rygel_user_config_test_SOURCES = rygel-configuration.vala \
				 rygel-user-config.vala \
				 rygel-user-config-test.vala
rygel_user_config_test_VALAFLAGS = \
	$(test_valaflags)
rygel_user_config_test_CFLAGS =  \
	$(test_cflags) \
	-DSYS_CONFIG_DIR='"$(sysconfigdir)"'
rygel_user_config_test_LDADD = \
	$(test_libs)

rygel_regression_SOURCES = \
	rygel-regression.vala
rygel_regression_VALAFLAGS = \
	$(test_server_valaflags)
rygel_regression_CFLAGS = \
	$(test_server_cflags)
rygel_regression_LDADD = \
	$(test_server_libs)

rygel_media_engine_test_SOURCES = \
	rygel-media-engine-test.vala
rygel_media_engine_test_VALAFLAGS = \
	$(test_server_valaflags)
rygel_media_engine_test_CFLAGS = \
	$(test_server_cflags) \
	-DTEST_DATA_FOLDER='"$(abs_srcdir)/data"' \
	-DTEST_ENGINE_PATH='"$(abs_top_builddir)/src/media-engines"' \
	-DBUILT_ENGINES='"@BUILT_ENGINES@"'
rygel_media_engine_test_LDADD = \
	$(test_server_libs)

if HAVE_GSTREAMER
check_PROGRAMS += \
	rygel-playbin-renderer-test \
	rygel-environment-test

test_librygel_renderer_gst_valaflags = \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
test_librygel_renderer_gst_cflags = \
	$(test_cflags) \
	$(LIBRYGEL_RENDERER_GST_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_CFLAGS)
test_librygel_renderer_gst_libs = \
	$(test_libs) \
	$(LIBRYGEL_RENDERER_GST_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_LIBS)
	
rygel_playbin_renderer_test_SOURCES = rygel-playbin-renderer-test.vala
rygel_playbin_renderer_test_VALAFLAGS = \
	--enable-experimental \
	$(test_librygel_renderer_gst_valaflags)
rygel_playbin_renderer_test_CFLAGS = \
	$(test_librygel_renderer_gst_cflags)
rygel_playbin_renderer_test_LDADD = \
	$(test_librygel_renderer_gst_libs)

rygel_environment_test_SOURCES = rygel-environment-test.vala
rygel_environment_test_VALAFLAGS = \
	--enable-experimental \
	$(test_librygel_renderer_gst_valaflags)
rygel_environment_test_CFLAGS = \
	$(test_librygel_renderer_gst_cflags)
rygel_environment_test_LDADD = \
	$(test_librygel_renderer_gst_libs)

endif

if BUILD_MEDIA_EXPORT_PLUGIN
check_PROGRAMS += plugins/media-export/regression

plugins_media_export_regression_SOURCES = \
	$(top_srcdir)/src/librygel-core/rygel-core-2.0.vapi \
	$(top_srcdir)/src/librygel-server/rygel-server-2.0.vapi \
	$(top_srcdir)/src/plugins/media-export/rygel-media-export.vapi \
	plugins/media-export/regression.vala
plugins_media_export_regression_CFLAGS = \
	$(test_cflags) \
	$(COLLATION_CFLAGS) \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-I$(top_srcdir)/src/plugins/media-export
plugins_media_export_regression_LDADD = \
	$(test_libs) \
	$(COLLATION_LIBS) \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS) \
	$(top_builddir)/src/plugins/media-export/librygel-media-export.la
plugins_media_export_regression_VALAFLAGS = \
	$(test_valaflags) \
	--enable-experimental \
	$(RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_VALAFLAGS)
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
