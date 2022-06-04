if valadoc.found()
renderer_gst_doc_common_args = [
        '--package-name', 'librygel-renderer-gst',
        '--package-version', '2.8',
        '-b', join_paths(meson.project_source_root(), 'src', 'librygel-renderer-gst'),
        '--vapidir', join_paths(meson.project_source_root(), 'vapi'),
        '--vapidir', join_paths(meson.project_source_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.project_build_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.project_build_root(), 'src', 'librygel-renderer'),
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
        '--pkg', 'rygel-renderer-2.8',
        '--pkg', 'gstreamer-1.0',
        '--pkg', 'gstreamer-audio-1.0'
]

custom_target('valadoc-renderer-gst',
    input: renderer_gst_sources,
    output: 'valadoc',
    depends : renderer_gst_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        renderer_gst_doc_common_args,
        renderer_gst_sources
    ]
)

if gtkdoc.found()
subdir('gtkdoc')
gtkdoc_renderer_gst_target = custom_target('gtkdoc-renderer-gst',
    input: renderer_gst_sources,
    output: 'gtkdoc',
    depends : renderer_gst_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        renderer_gst_doc_common_args,
        '--doclet', 'gtkdoc',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-renderer/rygel-renderer.h'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-renderer/librygel-renderer-2.8.so'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-core/librygel-core-2.8.so'),
        '-X', '-l',
        '-X', join_paths(meson.project_build_root(), 'src/librygel-renderer-gst/librygel-renderer-gst-2.8.so'),
        renderer_gst_sources
    ]
)
if get_option('api-docs')
    meson.add_install_script(install_doc, gtkdoc_renderer_gst_target,
                   join_paths(get_option('datadir'), 'gtk-doc/html/librygel-renderer-gst'))
endif
endif
endif
