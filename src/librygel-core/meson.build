core_sources = [
    'rygel-connection-manager.vala',
    'rygel-basic-management.vala',
    'rygel-basic-management-test.vala',
    'rygel-basic-management-test-ping.vala',
    'rygel-basic-management-test-nslookup.vala',
    'rygel-basic-management-test-traceroute.vala',
    'rygel-description-file.vala',
    'rygel-dlna-profile.vala',
    'rygel-energy-management.vala',
    'rygel-root-device.vala',
    'rygel-root-device-factory.vala',
    'rygel-dbus-interface.vala',
    'rygel-log-handler.vala',
    'rygel-meta-config.vala',
    'rygel-plugin-loader.vala',
    'rygel-recursive-module-loader.vala',
    'rygel-plugin.vala',
    'rygel-resource-info.vala',
    'rygel-media-device.vala',
    'rygel-configuration.vala',
    'rygel-base-configuration.vala',
    'rygel-cmdline-config.vala',
    'rygel-environment-config.vala',
    'rygel-user-config.vala',
    'rygel-state-machine.vala',
    'rygel-v1-hacks.vala',
    'rygel-icon-info.vala',
    'rygel-xml-utils.vala',
    'rygel-plugin-information.vala',
    'rygel-energy-management-helper.c',
    'rygel-build-config.vapi']

build_config = declare_dependency(include_directories : config_include,
                                  sources : 'rygel-build-config.vapi')


core_lib = library('rygel-core-2.6', core_sources,
        dependencies : core_deps,
        include_directories: [config_include, include_directories('.')],
        version: '2.0.4',
        c_args : ['-DG_LOG_DOMAIN="RygelCore"'],
        vala_gir : 'Rygel-2.6.gir',
        vala_header : 'rygel-core.h',
        install: true,
        install_dir : [true, rygel_includedir, true, false])

custom_target('RygelCore-2.6.typelib',
               command: [g_ir_compiler, '--output', '@OUTPUT@', '@INPUT@'],
               output: 'RygelCore-2.6.typelib',
               input: 'RygelCore-2.6.gir',
               depends: core_lib,
               install: true,
               install_dir: gir_dir)

custom_target('RygelCore-2.6.gir',
              command: [sed, '-e', 's,Rygel[.],RygelCore.,g',
                        '-e', 's,namespace name="Rygel",namespace name="RygelCore",g',
                        '@INPUT@'],
              input: 'Rygel-2.6.gir',
              output: 'RygelCore-2.6.gir',
              capture: true,
              install: true,
              install_dir: typelib_dir)

# need to add to get the current build dir as include dir
rygel_core = declare_dependency(include_directories: include_directories('.'),
                                dependencies: core_deps,
                                link_with: core_lib)

# necessary to be able to pass it to g-ir-compiler in other libs
core_girdir = meson.current_build_dir()
