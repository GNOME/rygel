#subdir('renderer-plguins')
#subdir('server-plugins')

executable('standalone-server',
           'standalone-server.c',
           dependencies : [gio, rygel_core, rygel_server],
           link_with : [core_lib, server_lib])

executable('standalone-ruih',
           'standalone-ruih.c',
           dependencies : [gio, rygel_core, rygel_ruih],
           link_with: [core_lib, ruih_lib])

executable('standalone-renderer-gst',
           'standalone-renderer-gst.c',
           dependencies : [gstreamer,
                           gstreamer_video,
                           rygel_core,
                           rygel_renderer,
                           rygel_renderer_gst],
           link_with: [core_lib, renderer_lib, renderer_gst_lib])

executable('fullscreen-renderer',
           'fullscreen-renderer.c',
           dependencies : [gstreamer_video,
                           gtk,
                           rygel_core,
                           rygel_renderer,
                           rygel_renderer_gst],
           link_with: [core_lib, renderer_lib, renderer_gst_lib])
