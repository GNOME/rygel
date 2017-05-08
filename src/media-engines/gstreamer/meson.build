media_engine_gst_sources = [
    'rygel-aac-transcoder.vala',
    'rygel-audio-transcoder.vala',
    'rygel-avc-transcoder.vala',
    'rygel-gst-data-source.vala',
    'rygel-gst-media-engine.vala',
    'rygel-gst-sink.vala',
    'rygel-gst-transcoder.vala',
    'rygel-gst-utils.vala',
    'rygel-l16-transcoder.vala',
    'rygel-mp2ts-transcoder.vala',
    'rygel-mp3-transcoder.vala',
    'rygel-video-transcoder.vala',
    'rygel-wmv-transcoder.vala'
    ]


library('rygel-media-engine-gst',
        media_engine_gst_sources,
        dependencies: [build_config, gee, gupnp_av, libxml, gio, rygel_core, rygel_server, gstreamer, gstreamer_pbu, gstreamer_base, gupnp_dlna],
        install: true,
        install_dir : rygel_enginedir)
