configure_file(input : 'ruih.plugin.in',
               output : 'ruih.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)

shared_module('rygel-ruih',
              ['rygel-ruih-module.vala', 'rygel-ruih-plugin.vala'],
              dependencies: [build_config, rygel_core, rygel_ruih],
              # Needed to avoid conflict with librarie's header
              vala_header : 'rygel-ruih-plugin.h',
              c_args : ['-DG_LOG_DOMAIN="RUIH"'],
              install : true,
              install_dir : rygel_plugindir)
