shared_module('rygel-example-renderer-plugin-c',
              ['example-renderer-plugin.h',
               'example-renderer-plugin.c',
               'example-player.h',
               'example-player.c'],
              c_args : '-DG_LOG_DOMAIN="ExampleRendererPluginC"',
              dependencies: [rygel_core, rygel_renderer],
              link_with : [core_lib, renderer_lib],
              install : true,
              install_dir : rygel_plugindir)

configure_file(input : 'example-renderer-c.plugin.in',
               output : 'example-renderer-c.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)
