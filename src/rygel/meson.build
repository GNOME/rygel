rygel_sources = [
        'rygel-acl.vala',
        'rygel-dbus-service.vala',
        'rygel-main.vala'
        ]
executable('rygel',
           rygel_sources,
           dependencies : rygel_deps + [build_config, rygel_core, rygel_server]
           )
