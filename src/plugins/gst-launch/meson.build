gst_launch_sources = [
    'rygel-gst-launch-plugin.vala',
    'rygel-gst-launch-root-container.vala',
    'rygel-gst-launch-audio-item.vala',
    'rygel-gst-launch-video-item.vala']

library('rygel-gst-launch',
        gst_launch_sources,
        dependencies: gst_launch_plugin_deps + [build_config, rygel_core, rygel_server],
        install : true,
        install_dir : rygel_plugindir)
