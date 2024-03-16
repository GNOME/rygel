renderer_sources = files(
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
    'rygel-volume.vala'
)

renderer_lib = library('rygel-renderer-2.8', renderer_sources,
        dependencies : renderer_deps + [build_config, rygel_core],
        version: lib_version,
        darwin_versions : darwin_versions,
        c_args : ['-DG_LOG_DOMAIN="RygelRenderer"'],
        vala_gir : 'Rygel-2.8.gir',
        vala_header : 'rygel-renderer.h',
        install: true,
        install_dir : [true, rygel_includedir, true, false])
install_data('rygel-renderer-2.8.deps', install_dir : rygel_vapidir)

if g_ir_compiler.found() and get_option('introspection').allowed()
# For details on the GIR / typelib generation process, see
# librygel-core/meson.build
renderer_gir = custom_target('RygelRenderer-2.8.gir',
              command: [sed, '-e', 's,Rygel[.],RygelRenderer.,g',
                                          '-e', 's,namespace name="Rygel",namespace name="RygelRenderer",g',
                                          '-e', 's,RygelRenderer[.]Plugin,RygelCore.Plugin,g',
                                          '-e', 's,RygelRenderer[.]MediaDevice,RygelCore.MediaDevice,g',
                                          '-e', 's,RygelRenderer[.]DLNAProfile,RygelCore.DLNAProfile,g',
                                          '-e', 's|<package name="rygel-renderer-2.8"/>|<include name="RygelCore" version="2.8"/><package name="rygel-renderer-2.8"/>|',
                        join_paths(meson.current_build_dir(), 'Rygel-2.8.gir')],
              output: 'RygelRenderer-2.8.gir',
              depends: renderer_lib,
              capture: true,
              install: true,
              install_dir: gir_dir)

custom_target('RygelRenderer-2.8.typelib',
               command: [g_ir_compiler,
                        '--output', '@OUTPUT@',
                        '--includedir', core_girdir,
                        join_paths(meson.current_build_dir(), 'RygelRenderer-2.8.gir')],
               output: 'RygelRenderer-2.8.typelib',
               depends: [ renderer_lib, renderer_gir, core_gir ],
               install: true,
               install_dir: typelib_dir)
endif


rygel_renderer = declare_dependency(include_directories : include_directories('.'),
                                    dependencies : renderer_deps,
                                    link_with: renderer_lib)

renderer_girdir = meson.current_build_dir()
