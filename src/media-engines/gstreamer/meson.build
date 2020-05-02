configure_file(input : 'media-engine-gst.plugin.in',
               output : 'media-engine-gst.plugin',
               configuration : plugin_config,
               install_dir : rygel_enginedir)

media_engine_gst_sources = [
    'rygel-aac-transcoder.vala',
    'rygel-audio-transcoder.vala',
    'rygel-avc-transcoder.vala',
    'rygel-gst-data-source.vala',
    'rygel-gst-transcoding-data-source.vala',
    'rygel-gst-media-engine.vala',
    'rygel-gst-sink.vala',
    'rygel-gst-transcoder.vala',
    'rygel-gst-utils.vala',
    'rygel-jpeg-transcoder.vala',
    'rygel-l16-transcoder.vala',
    'rygel-mp2ts-transcoder.vala',
    'rygel-mp3-transcoder.vala',
    'rygel-video-transcoder.vala',
    'rygel-wmv-transcoder.vala'
    ]


shared_module('rygel-media-engine-gst',
              media_engine_gst_sources,
              dependencies: media_engine_gst_dep + [build_config, rygel_core, rygel_server],
              c_args : ['-DG_LOG_DOMAIN="MediaEngine-GStreamer"'],
              install: true,
              install_dir : rygel_enginedir)
