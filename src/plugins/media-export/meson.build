configure_file(input : 'media-export.plugin.in',
               output : 'media-export.plugin',
               configuration : plugin_config,
               install_dir : rygel_plugindir)

constants = static_library('mx-constants',
                           'constants.vala',
                           dependencies : glib,
                           vala_vapi: 'mx-constants.vapi',
                           install : false)

mx_extract_sources = [
    'rygel-media-export-extract.vala',
    'rygel-media-export-dvd-parser.vala',
    'rygel-media-export-playlist-extractor.vala',
    'rygel-media-export-image-extractor.vala',
    'rygel-media-export-extractor.vala',
    'rygel-media-export-generic-extractor.vala']

mx_extract = executable('mx-extract',
                        mx_extract_sources,
                        dependencies : mx_export_deps + [gssdp],
                        c_args : ['-DG_LOG_DOMAIN="MxExtract"'],
                        link_with: constants,
                        install: true,
                        install_dir: rygel_libexecdir)

mx_sources = [
    'rygel-media-export-plugin.vala',
    'rygel-media-export-db-container.vala',
    'rygel-media-export-sql-factory.vala',
    'rygel-media-export-media-cache.vala',
    'rygel-media-export-media-cache-upgrader.vala',
    'rygel-media-export-metadata-extractor.vala',
    'rygel-media-export-null-container.vala',
    'rygel-media-export-dummy-container.vala',
    'rygel-media-export-root-container.vala',
    'rygel-media-export-query-container.vala',
    'rygel-media-export-query-container-factory.vala',
    'rygel-media-export-node-query-container.vala',
    'rygel-media-export-leaf-query-container.vala',
    'rygel-media-export-recursive-file-monitor.vala',
    'rygel-media-export-harvester.vala',
    'rygel-media-export-harvesting-task.vala',
    'rygel-media-export-item-factory.vala',
    'rygel-media-export-object-factory.vala',
    'rygel-media-export-writable-db-container.vala',
    'rygel-media-export-playlist-root-container.vala',
    'rygel-media-export-playlist-container.vala',
    'rygel-media-export-music-item.vala',
    'rygel-media-export-video-item.vala',
    'rygel-media-export-photo-item.vala',
    'rygel-media-export-playlist-item.vala',
    'rygel-media-export-trackable-db-container.vala',
    'rygel-media-export-updatable-object.vala',
    'rygel-media-export-dvd-container.vala',
    'rygel-media-export-dvd-track.vala']

shared_module('rygel-media-export',
              mx_sources,
              dependencies : mx_plugin_deps + [rygel_core, rygel_server, rygel_db],
              c_args : ['-DG_LOG_DOMAIN="MediaExport"'],
              link_with : constants,
              install: true,
              install_dir : rygel_plugindir)
