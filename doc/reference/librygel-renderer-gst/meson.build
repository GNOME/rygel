if valadoc.found()
renderer_gst_doc_common_args = [
        '--package-name', 'librygel-renderer-gst',
        '--package-version', '2.6',
        '-b', join_paths(meson.source_root(), 'src', 'librygel-renderer-gst'),
        '--vapidir', join_paths(meson.source_root(), 'vapi'),
        '--vapidir', join_paths(meson.source_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.build_root(), 'src/librygel-core'),
        '--vapidir', join_paths(meson.build_root(), 'src', 'librygel-renderer'),
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
        '--pkg', 'rygel-renderer-2.6',
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
        '-o', 'valadoc',
        renderer_gst_sources
    ]
)

if gtkdoc.found()
custom_target('gtkdoc-renderer-gst',
    input: renderer_gst_sources,
    output: 'gtkdoc',
    depends : renderer_gst_lib,
    build_by_default : get_option('api-docs'),
    command :
    [
        valadoc,
        renderer_gst_doc_common_args,
        '--doclet', 'gtkdoc',
        '-o', 'gtkdoc',
        '-X', join_paths(meson.build_root(), 'src/librygel-renderer/rygel-renderer.h'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-renderer/librygel-renderer-2.6.so'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-core/librygel-core-2.6.so'),
        '-X', '-l',
        '-X', join_paths(meson.build_root(), 'src/librygel-renderer-gst/librygel-renderer-gst-2.6.so'),
        renderer_gst_sources
    ]
)
if get_option('api-docs')
    install_subdir('gtkdoc/html',
                   install_dir : join_paths(get_option('datadir'), 'gtk-doc/html/librygel-renderer-gst'),
                   strip_directory : true)
endif
endif
endif
