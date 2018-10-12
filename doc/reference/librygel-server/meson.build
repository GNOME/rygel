server_doc_common_args = [
        '--package-name', 'librygel-server',
        '--package-version', '2.6',
        '-b', join_paths(meson.source_root(), 'src', 'librygel-server'),
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
        '--pkg', 'gupnp-av-1.0',
        '--pkg', 'rygel-core-2.6',
        '--pkg', 'libmediaart-2.0'
]

custom_target('valadoc-server',
    input: server_sources,
    output: 'valadoc',
    depends : server_lib,
    build_by_default : true,
    command :
    [
        valadoc,
        server_doc_common_args,
        '-o', 'valadoc',
        server_sources
    ]
)

custom_target('gtkdoc-server',
    input: server_sources,
    output: 'gtkdoc',
    depends : server_lib,
    build_by_default : true,
    command :
    [
        valadoc,
        server_doc_common_args,
        '--doclet', 'gtkdoc',
        '-o', 'gtkdoc',
        '-X', join_paths(meson.build_root(), 'src/librygel-server/rygel-server.h'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-server/librygel-server-2.6.so'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-core/librygel-core-2.6.so'),
        server_sources
    ]
)
