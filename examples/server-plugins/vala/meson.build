shared_module('rygel-example-server-plugin-vala',
              ['example-server-plugin-vala.vala',
               'example-root-container-vala.vala'],
              c_args : '-DG_LOG_DOMAIN="ExampleServerPluginVala"',
              dependencies : common_deps + [gupnp_av, rygel_core, rygel_server],
              install : true,
              install_dir : rygel_plugindir)

configure_file(input : 'example-server-vala.plugin.in',
               output : 'example-server-vala.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)
