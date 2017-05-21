ruih_sources = [
    'rygel-ruih-filter-entry.vala',
    'rygel-ruih-icon-elem.vala',
    'rygel-ruih-protocol-elem.vala',
    'rygel-ruih-server-plugin.vala',
    'rygel-ruih-server.vala',
    'rygel-ruih-service.vala',
    'rygel-ruih-service-error.vala',
    'rygel-ruih-servicemanager.vala',
    'rygel-ruih-ui-elem.vala',
    'rygel-ruih-ui-listing.vala',
    'rygel-ruih-wildcard-filter-entry.vala'
]

ruih_lib = library('rygel-ruih-2.6', ruih_sources,
        dependencies : ruih_deps + [build_config, rygel_core],
        version: '1.0.0',
        vala_header : 'rygel-ruih.h',
        install: true,
        install_dir : [true, true, true])

# need to add to get the current build dir as include dir
rygel_ruih = declare_dependency(include_directories: include_directories('.'),
                                  dependencies : ruih_deps,
                                  link_with: ruih_lib)

