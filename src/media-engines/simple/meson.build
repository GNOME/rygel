configure_file(input : 'media-engine-simple.plugin.in',
               output : 'media-engine-simple.plugin',
               configuration : plugin_config,
               install_dir : rygel_enginedir)

media_engine_simple_sources = ['rygel-simple-media-engine.vala',
                               'rygel-simple-data-source.vala']

shared_module('rygel-media-engine-simple',
              media_engine_simple_sources,
              c_args : ['-DG_LOG_DOMAIN="MediaEngine-Simple"'],
              dependencies: [build_config, rygel_core, rygel_server, posix],
              install: true,
              install_dir : rygel_enginedir)
