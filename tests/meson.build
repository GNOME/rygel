test_deps = common_deps

searchable_container_test = executable(
    'rygel-searchable-container-test',
    files('searchable-container/rygel-searchable-container.vala',
          'searchable-container/test.vala'),
    dependencies : [test_deps, gupnp_av, gio, gssdp]
)

object_creator_test = executable(
    'rygel-object-creator-test',
    files('object-creator/test.vala',
          'object-creator/rygel-object-creator.vala',
          'object-creator/rygel-dlna-profile.vala',
          'object-creator/rygel-serializer.vala',
          'object-creator/rygel-m3u-playlist.vala',
          'object-creator/rygel-state-machine.vala',
          'object-creator/rygel-search-expression.vala',
          'object-creator/rygel-relational-expression.vala',
          'object-creator/rygel-logical-expression.vala',
          'object-creator/rygel-search-criteria-parser.vala'),
    dependencies : [test_deps, gio, gupnp_av, soup, libxml]
)

user_config_test = executable(
    'rygel-user-config-test',
    files('rygel-configuration.vala',
          'rygel-user-config.vala',
          'rygel-user-config-test.vala'),
    vala_args : ['--pkg', 'rygel-build-config', '--vapidir', join_paths(meson.project_source_root(), 'src/librygel-core')],
    include_directories : config_include,
    dependencies : [test_deps, gio]
)

regression_test = executable(
    'rygel-regression-test',
    files('rygel-regression.vala'),
    dependencies : [test_deps, gio, rygel_core, rygel_server]
)

database_test = executable(
    'rygel-database-test.vala',
    files('rygel-database-test.vala'),
    dependencies : [rygel_db]
)

environment_test = executable(
    'rygel-environment-test',
    files('rygel-environment-test.vala'),
    dependencies : [gstreamer]
)

playbin_renderer_test = executable(
    'rygel-playbin-renderer-test',
    files('rygel-playbin-renderer-test.vala'),
    dependencies : [gstreamer, rygel_core, rygel_renderer, rygel_renderer_gst]
)

http_time_seek_test = executable(
    'rygel-http-time-seek-test',
    files(
        'time-seek/rygel-http-seek.vala',
        'time-seek/rygel-http-time-seek-request.vala',
        'time-seek/rygel-http-time-seek-test.vala'
    ),
    dependencies : [glib, gobject]
)

test('rygel-plugin-loader-test',
    executable(
        'rygel-plugin-loader-test',
        files(
            'plugin-loader/rygel-plugin-loader-test.vala'
        ),
        dependencies : [
            rygel_core
        ]
    ),
    workdir : meson.current_source_dir(),
)

test('rygel-meta-config-test',
    executable(
        'rygel-meta-config-test',
        files(
            'rygel-meta-config-test.vala'
        ),
        dependencies : [
            rygel_core
        ]
    )
)

test('rygel-searchable-container-test', searchable_container_test)
test('rygel-object-creator-test', object_creator_test)
test('rygel-regression-test', regression_test)
test('rygel-database-test', database_test)
test('rygel-environment-test', environment_test)
test('rygel-playbin-renderer-test', playbin_renderer_test)

# Up the timeout, the test itself is waiting 10s per round for changes, doing 4 rounds
test('rygel-user-config-test', user_config_test, timeout : 50)

test('rygel-http-time-seek-test', http_time_seek_test)
