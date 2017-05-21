
shared_module('rygel-playbin',
              ['rygel-playbin-module.vala', 'rygel-playbin-plugin.vala'],
              dependencies: [build_config, rygel_core, rygel_renderer, rygel_renderer_gst],
              c_args : ['-DG_LOG_DOMAIN="Playbin"'],
              install : true,
              install_dir : rygel_plugindir)
