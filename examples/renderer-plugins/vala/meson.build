shared_module('rygel-example-renderer-plugin-vala',
              ['example-renderer-plugin-vala.vala',
               'example-player-vala.vala'],
              c_args : '-DG_LOG_DOMAIN="ExampleRendererPluginVala"',
              dependencies : common_deps + [gupnp_av, rygel_core, rygel_renderer],
              install : true,
              install_dir : rygel_plugindir)

configure_file(input : 'example-renderer-vala.plugin.in',
               output : 'example-renderer-vala.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)
