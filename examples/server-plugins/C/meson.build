shared_module('rygel-example-server-plugin-c',
              ['example-server-plugin.h',
               'example-server-plugin.c',
               'example-root-container.h',
               'example-root-container.c'],
              c_args : '-DG_LOG_DOMAIN="ExampleServerPluginC"',
              dependencies: [rygel_core, rygel_server],
              install : true,
              install_dir : rygel_plugindir)

configure_file(input : 'example-server-c.plugin.in',
               output : 'example-server-c.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)
