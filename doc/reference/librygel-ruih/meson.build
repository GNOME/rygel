if valadoc.found()
ruih_doc_common_args = [
        '--package-name', 'librygel-ruih',
        '--package-version', '2.8',
        '-b', join_paths(meson.project_source_root(), 'src', 'librygel-ruih'),
        '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
        '--vapidir', join_paths(meson.project_source_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.project_build_root(), 'src/librygel-core'),
        '--pkg', 'rygel-build-config',
        '--force',
        '--directory', '@OUTPUT@',
        '--pkg', 'gio-2.0',
        '--pkg', 'gee-0.8',
        '--pkg', 'gupnp-1.6',
        '--pkg', 'rygel-core-2.8',
]

custom_target('valadoc-ruih',
    input: ruih_sources,
    output: 'valadoc',
    depends : ruih_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        ruih_doc_common_args,
        ruih_sources
    ]
)

if gtkdoc.found()
subdir('gtkdoc')
gtkdoc_ruih_target = custom_target('gtkdoc-ruih',
    input: ruih_sources,
    output: 'gtkdoc',
    depends : ruih_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        ruih_doc_common_args,
        '--doclet', 'gtkdoc',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-ruih/rygel-ruih.h'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-ruih/librygel-ruih-2.8.so'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-core/librygel-core-2.8.so'),
        ruih_sources
    ]
)
if get_option('api-docs')
    meson.add_install_script(install_doc, gtkdoc_ruih_target,
                   join_paths(get_option('datadir'), 'gtk-doc/html/librygel-ruih'))
endif
endif
endif
