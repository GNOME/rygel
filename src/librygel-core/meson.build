core_sources = files(
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
    'dlna150-hacks.vala',
    'agent-matcher.vala',
    'rygel-build-config.vapi')

build_config = declare_dependency(include_directories : config_include,
                                  sources : 'rygel-build-config.vapi')


# Rygel GIR generation is a tad special. We need to hammer in custom namespaces
# since the libraries used to be in one binary. So
# Step one: Build the library, generate the GIR from vala but do not install it
core_lib = library('rygel-core-2.8', core_sources,
        dependencies : core_deps,
        include_directories: [config_include, include_directories('.')],
        version: lib_version,
        darwin_versions: darwin_versions,
        c_args : ['-DG_LOG_DOMAIN="RygelCore"'],
        vala_gir : 'Rygel-2.8.gir',
        vala_header : 'rygel-core.h',
        install: true,
        install_dir : [true, rygel_includedir, true, false])
install_data('rygel-core-2.8.deps', install_dir : rygel_vapidir)

if g_ir_compiler.found() and get_option('introspection').allowed()
# Step two: Do the namespace magic with sed
# We cannot use input: here since the generated ninja build file does not seem
# to know that Rygel-2.8.gir is a result of building rygel-core-2.8 target
# The custom_target call depends on the core_lib to make sure it is build before
# and the name of the generated GIR is passed directly to sed as part of the
# commandline
core_gir = custom_target('RygelCore-2.8.gir',
              command: [sed, '-e', 's,Rygel[.],RygelCore.,g',
                        '-e', 's,namespace name="Rygel",namespace name="RygelCore",g',
                        join_paths(meson.current_build_dir(), 'Rygel-2.8.gir')],
              depends: core_lib,
              output: 'RygelCore-2.8.gir',
              capture: true,
              install: true,
              install_dir: gir_dir)

# Step three: Compile the typelib. The dependency issue is similar to step two,
# so we depend on the custom_target from that step and pass the input through
# commandline.
custom_target('RygelCore-2.8.typelib',
               command: [g_ir_compiler, '--output', '@OUTPUT@', join_paths(meson.current_build_dir(), 'RygelCore-2.8.gir')],
               output: 'RygelCore-2.8.typelib',
               depends: [ core_lib, core_gir ],
               install: true,
               install_dir: typelib_dir)
endif

# need to add to get the current build dir as include dir
rygel_core = declare_dependency(include_directories: include_directories('.'),
                                dependencies: core_deps,
                                link_with: core_lib)

# necessary to be able to pass it to g-ir-compiler in other libs
core_girdir = meson.current_build_dir()
