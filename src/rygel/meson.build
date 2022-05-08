rygel_sources = [
        'rygel-acl.vala',
        'application.vala',
        'rygel-dbus-service.vala'
        ]
executable('rygel',
           rygel_sources,
           c_args : ['-DG_LOG_DOMAIN="Rygel"'],
           dependencies : rygel_deps + [build_config, rygel_core, rygel_server, dependency('x11')],
           install: true
           )
