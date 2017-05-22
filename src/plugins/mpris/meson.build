configure_file(input : 'mpris.plugin.in',
               output : 'mpris.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)

rygel_mpris_sources = [
    'rygel-mpris-player.vala',
    'rygel-mpris-plugin.vala',
    'rygel-mpris-plugin-factory.vala',
    'rygel-mpris-interfaces.vala',
    'rygel-free-desktop-interfaces.vala']

shared_module('rygel-mpris',
              rygel_mpris_sources,
              dependencies : [build_config, rygel_core, rygel_renderer],
              c_args : ['-DG_LOG_DOMAIN="MPRIS"'],
              install: true,
              install_dir: rygel_plugindir)
