renderer_gst_sources = [
    'rygel-playbin-player.vala',
    'rygel-playbin-renderer.vala',
]

renderer_gst_lib = library('rygel-renderer-gst-2.6', renderer_gst_sources,
        dependencies : renderer_gst_deps + [build_config, rygel_core, rygel_renderer],
        version: '2.0.4',
        vala_gir : 'Rygel-2.6.gir',
        vala_header : 'rygel-renderer-gst.h',
        install: true,
        install_dir : [true, true, true, false])

custom_target('RygelRendererGst-2.6.typelib',
               command: [g_ir_compiler,
                        '--output', '@OUTPUT@',
                        '--includedir', core_girdir,
                        '--includedir', renderer_girdir,
                        '@INPUT@'],
               output: 'RygelRendererGst-2.6.typelib',
               input: 'RygelRendererGst-2.6.gir',
               depends: [renderer_gst_lib, renderer_lib],
               install: true,
               install_dir: typelib_dir)

custom_target('RygelRendererGst-2.6.gir',
              command: [sed, '-e', 's,Rygel[.],RygelRendererGst.,g',
                             '-e', 's,RygelRendererGst[.]MediaRenderer,RygelRenderer.MediaRenderer,g',
                             '-e', 's,RygelRendererGst[.]MediaPlayer,RygelRenderer.MediaPlayer,g',
                             '-e', 's,namespace name="Rygel",namespace name="RygelRendererGst",g',
                             '-e', 's,RygelRendererGst[.]Plugin,RygelCore.Plugin,g',
                             '-e', 's,<package name="rygel-renderer-gst-2.6"/>,<include name="RygelCore" version="2.6"/><include name="RygelRenderer" version="2.6"/><package name="rygel-renderer-gst-2.6"/>,',
                        '@INPUT@'],
              input: 'Rygel-2.6.gir',
              output: 'RygelRendererGst-2.6.gir',
              capture: true,
              install: true,
              install_dir: join_paths(get_option('datadir'),'gir-1.0'))

