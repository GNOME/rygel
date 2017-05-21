renderer_sources = [
    'rygel-media-renderer-plugin.vala',
    'rygel-media-player.vala',
    'rygel-media-renderer.vala',
    'rygel-player-controller.vala',
    'rygel-av-transport.vala',
    'rygel-default-player-controller.vala',
    'rygel-rendering-control.vala',
    'rygel-sink-connection-manager.vala',
    'rygel-time-utils.vala',
    'rygel-changelog.vala',
    'rygel-volume.vala']

renderer_lib = library('rygel-renderer-2.6', renderer_sources,
        dependencies : renderer_deps + [build_config, rygel_core],
        version: '2.0.4',
        c_args : ['-DG_LOG_DOMAIN="RygelRenderer"'],
        vala_gir : 'Rygel-2.6.gir',
        vala_header : 'rygel-renderer.h',
        install: true,
        install_dir : [true, rygel_includedir, true, false])

custom_target('RygelRenderer-2.6.typelib',
               command: [g_ir_compiler,
                        '--output', '@OUTPUT@',
                        '--includedir', core_girdir,
                        '@INPUT@'],
               output: 'RygelRenderer-2.6.typelib',
               input: 'RygelRenderer-2.6.gir',
               depends: renderer_lib,
               install: true,
               install_dir: typelib_dir)

custom_target('RygelRenderer-2.6.gir',
              command: [sed, '-e', 's,Rygel[.],RygelRenderer.,g',
                                          '-e', 's,namespace name="Rygel",namespace name="RygelRenderer",g',
                                          '-e', 's,RygelRenderer[.]Plugin,RygelCore.Plugin,g',
                                          '-e', 's,RygelRenderer[.]MediaDevice,RygelCore.MediaDevice,g',
                                          '-e', 's|<package name="rygel-renderer-2.6"/>|<include name="RygelCore" version="2.6"/><package name="rygel-renderer-2.6"/>|',
                        '@INPUT@'],
              input: 'Rygel-2.6.gir',
              output: 'RygelRenderer-2.6.gir',
              capture: true,
              install: true,
              install_dir: join_paths(get_option('datadir'),'gir-1.0'))
rygel_renderer = declare_dependency(include_directories : include_directories('.'),
                                    dependencies : renderer_deps,
                                    link_with: renderer_lib)

renderer_girdir = meson.current_build_dir()
