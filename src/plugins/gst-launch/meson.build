configure_file(input : 'gst-launch.plugin.in',
               output : 'gst-launch.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)

gst_launch_sources = [
    'rygel-gst-launch-plugin.vala',
    'rygel-gst-launch-root-container.vala',
    'rygel-gst-launch-audio-item.vala',
    'rygel-gst-launch-video-item.vala']

shared_module('rygel-gst-launch',
              gst_launch_sources,
              dependencies: gst_launch_plugin_deps + [build_config, rygel_core, rygel_server],
              c_args : ['-DG_LOG_DOMAIN="GstLaunch"'],
              install : true,
              install_dir : rygel_plugindir)
