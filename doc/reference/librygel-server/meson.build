if valadoc.found()
server_doc_common_args = [
        '--package-name', 'librygel-server',
        '--package-version', '2.8',
        '-b', join_paths(meson.project_source_root(), 'src', 'librygel-server'),
        '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
        '--vapidir', join_paths(meson.project_source_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.project_build_root(), 'src/librygel-core'),
        '--pkg', 'rygel-build-config',
        '--force',
        '--directory', '@OUTPUT@',
        '--pkg', 'gio-2.0',
        '--pkg', 'gee-0.8',
        '--pkg', 'gupnp-1.6',
        '--pkg', 'gmodule-2.0',
        '--pkg', 'posix',
        '--pkg', 'gupnp-av-1.0',
        '--pkg', 'rygel-core-2.8',
        '--pkg', 'libmediaart-2.0'
]

custom_target('valadoc-server',
    input: server_sources,
    output: 'valadoc',
    depends : server_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        server_doc_common_args,
        server_sources
    ]
)

if gtkdoc.found()
subdir('gtkdoc')
gtkdoc_server_target = custom_target('gtkdoc-server',
    input: server_sources,
    output: 'gtkdoc',
    depends : server_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        server_doc_common_args,
        '--doclet', 'gtkdoc',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-server/rygel-server.h'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-server/librygel-server-2.8.so'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-core/librygel-core-2.8.so'),
        server_sources
    ]
)
if get_option('api-docs')
    meson.add_install_script(install_doc, gtkdoc_server_target,
                   join_paths(get_option('datadir'), 'gtk-doc/html/librygel-server'))
endif
endif
endif
