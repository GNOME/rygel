configure_file(input : 'external.plugin.in',
               output : 'external.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)

rygel_external_sources = [
    'rygel-external-container.vala',
    'rygel-external-dummy-container.vala',
    'rygel-external-item-factory.vala',
    'rygel-external-album-art-factory.vala',
    'rygel-external-thumbnail-factory.vala',
    'rygel-external-plugin.vala',
    'rygel-external-interfaces.vala',
    'rygel-external-plugin-factory.vala',
    'rygel-external-icon-factory.vala',
    'rygel-external-variant-util.vala',
    'rygel-free-desktop-interfaces.vala']

shared_module('rygel-external',
              rygel_external_sources,
              dependencies : external_plugin_deps + [build_config, rygel_core, rygel_server],
              c_args : ['-DG_LOG_DOMAIN="External"'],
              install: true,
              install_dir: rygel_plugindir)
