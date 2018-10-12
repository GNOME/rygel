db_doc_common_args = [
        '--package-name', 'librygel-db',
        '--package-version', '2.6',
        '-b', join_paths(meson.source_root(), 'src', 'librygel-db'),
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
        '--vapidir', join_paths(meson.source_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.build_root(), 'src/librygel-core'),
        '--target-glib=2.32',
        '--pkg', 'rygel-build-config',
        '--force',
        '--directory', '@OUTPUT@',
        '--pkg', 'gio-2.0',
        '--pkg', 'gee-0.8',
        '--pkg', 'gupnp-1.0',
        '--pkg', 'gmodule-2.0',
        '--pkg', 'posix',
        '--pkg', 'sqlite3',
        '--pkg', 'gupnp-av-1.0',
        '--pkg', 'rygel-core-2.6',
]

custom_target('valadoc-db',
    input: db_sources,
    output: 'valadoc',
    depends: db_lib,
    build_by_default : true,
    command :
    [
        valadoc,
        db_doc_common_args,
        '-o', 'valadoc',
        db_sources
    ]
)

custom_target('gtkdoc-db',
    input: db_sources,
    output: 'gtkdoc',
    depends : db_lib,
    build_by_default : true,
    command :
    [
        valadoc,
        db_doc_common_args,
        '--doclet', 'gtkdoc',
        '-o', 'gtkdoc',
        '-X', join_paths(meson.build_root(), 'src/librygel-db/rygel-db.h'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-db/librygel-db-2.6.so'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-core/librygel-core-2.6.so'),
        db_sources
    ]
)
