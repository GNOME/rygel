renderer_gst_sources = files(
    'rygel-playbin-player.vala',
    'rygel-playbin-renderer.vala',
)

renderer_gst_lib = library('rygel-renderer-gst-2.8', renderer_gst_sources,
        dependencies : renderer_gst_deps + [build_config, rygel_core, rygel_renderer],
        version: lib_version,
        darwin_versions : darwin_versions,
        c_args : ['-DG_LOG_DOMAIN="RygelRendererGst"'],
        vala_gir : 'Rygel-2.8.gir',
        vala_header : 'rygel-renderer-gst.h',
        install: true,
        install_dir : [true, rygel_includedir, true, false])
install_data('rygel-renderer-gst-2.8.deps', install_dir : rygel_vapidir)

if g_ir_compiler.found() and get_option('introspection').allowed()
# For details on the GIR/typelib generating process, see
# librygel-core/meson.build
renderer_gst_gir = custom_target('RygelRendererGst-2.8.gir',
              command: [sed, '-e', 's,Rygel[.],RygelRendererGst.,g',
                             '-e', 's,RygelRendererGst[.]MediaRenderer,RygelRenderer.MediaRenderer,g',
                             '-e', 's,RygelRendererGst[.]MediaPlayer,RygelRenderer.MediaPlayer,g',
                             '-e', 's,namespace name="Rygel",namespace name="RygelRendererGst",g',
                             '-e', 's,RygelRendererGst[.]Plugin,RygelCore.Plugin,g',
                             '-e', 's,RygelRendererGst[.]DLNAProfile,RygelCore.DLNAProfile,g',
                             '-e', 's,<package name="rygel-renderer-gst-2.8"/>,<include name="RygelCore" version="2.8"/><include name="RygelRenderer" version="2.8"/><package name="rygel-renderer-gst-2.8"/>,',
                        join_paths(meson.current_build_dir(), 'Rygel-2.8.gir')],
              output: 'RygelRendererGst-2.8.gir',
              depends: renderer_gst_lib,
              capture: true,
              install: true,
              install_dir: gir_dir)

custom_target('RygelRendererGst-2.8.typelib',
               command: [g_ir_compiler,
                        '--output', '@OUTPUT@',
                        '--includedir', core_girdir,
                        '--includedir', renderer_girdir,
                        join_paths(meson.current_build_dir(), 'RygelRendererGst-2.8.gir')],
               output: 'RygelRendererGst-2.8.typelib',
               depends: [renderer_gst_lib, renderer_lib, renderer_gst_gir, renderer_gir],
               install: true,
               install_dir: typelib_dir)
endif

rygel_renderer_gst = declare_dependency(include_directories : include_directories('.'),
                                        dependencies : renderer_gst_deps,
                                        link_with: renderer_gst_lib)
