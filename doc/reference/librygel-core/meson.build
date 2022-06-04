if valadoc.found()
core_doc_common_args = [
        '--package-name', 'librygel-core',
        '--package-version', '2.8',
        '-b', join_paths(meson.project_source_root(), 'src', 'librygel-core'),
        '--pkg', 'rygel-build-config',
        '--force',
        '--directory', '@OUTPUT@',
        '--pkg', 'gio-2.0',
        '--pkg', 'gee-0.8',
        '--pkg', 'gupnp-1.6',
        '--pkg', 'gmodule-2.0',
        '--pkg', 'posix'
 ]

custom_target('valadoc-core',
    input: core_sources,
    output: 'valadoc',
    depends : core_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        core_doc_common_args,
        core_sources
    ]
)

if gtkdoc.found()
    subdir('gtkdoc')

gtkdoc_core_target = custom_target('gtkdoc-core',
    input: core_sources,
    output: 'gtkdoc',
    depends : core_lib,
    build_by_default : get_option('api-docs'),
    command:
    [
        valadoc,
        '--doclet', 'gtkdoc',
        core_doc_common_args,
        '-X', join_paths(meson.project_build_root(), 'src/librygel-core/rygel-core.h'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-core/librygel-core-2.8.so'),
        '-b', join_paths(meson.project_source_root(), 'src', 'librygel-core'),
        core_sources
    ]
)

if get_option('api-docs')
    meson.add_install_script(install_doc, gtkdoc_core_target,
                   join_paths(get_option('datadir'), 'gtk-doc/html/librygel-core'))
endif
endif
endif
