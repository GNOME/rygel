project('rygel', ['vala', 'c'],
        version : '0.35.0')

rygel_sysconfdir = join_paths(get_option('prefix'), get_option('sysconfdir'))
rygel_datadir = join_paths(get_option('prefix'), get_option('datadir'))
rygel_libdir = join_paths(get_option('prefix'), get_option('libdir'))
rygel_plugindir = join_paths(rygel_libdir, 'rygel-2.6', 'plugins')
rygel_enginedir = join_paths(rygel_libdir, 'rygel-2.6', 'engines')
rygel_libexecdir = join_paths(get_option('prefix'), get_option('libexecdir'),
    'rygel')
rygel_presetdir = join_paths(rygel_datadir, 'rygel', 'presets')
rygel_icondir = join_paths(rygel_datadir, 'icons', 'hicolor')
rygel_bigicondir = join_paths(rygel_datadir, 'rygel', 'icons', '120x120')
rygel_smallicondir = join_paths(rygel_datadir, 'rygel', 'icons', '48x48')
rygel_includedir = join_paths(get_option('includedir'), 'rygel-2.6')
rygel_vapidir = join_paths(rygel_datadir, 'vala', 'vapi')

rygel_systemduserdir = join_paths(get_option('prefix'), 'lib', 'systemd', 'user')
plugin_config = configuration_data()
plugin_config.set('VERSION', meson.project_version())

conf = configuration_data()
conf.set('GETTEXT_PACKAGE', '"rygel"')
conf.set('PACKAGE_NAME', '"Rygel"')
conf.set('PACKAGE_STRING', '"Rygel @0@"'.format(meson.project_version()))
conf.set('PACKAGE_VERSION', '"@0@"'.format(meson.project_version()))
conf.set('PACKAGE_URL', '"http://www.rygel-project.org"')
conf.set('ENGINE_DIR', '"@0@"'.format(rygel_enginedir))
conf.set('PRESET_DIR', '"@0@"'.format(rygel_presetdir))
conf.set('DATA_DIR', '"@0@"'.format(rygel_datadir))
conf.set('PLUGIN_DIR', '"@0@"'.format(rygel_plugindir))
conf.set('BIG_ICON_DIR', '"@0@"'.format(rygel_bigicondir))
conf.set('SMALL_ICON_DIR', '"@0@"'.format(rygel_smallicondir))
conf.set('SYS_CONFIG_DIR', '"@0@"'.format(rygel_sysconfdir))
conf.set('LOCALEDIR', '"@0@"'.format(join_paths(get_option('prefix'), get_option('localedir'))))
conf.set('MX_EXTRACT_PATH', '"@0@"'.format(join_paths(rygel_libexecdir, 'mx-extract')))
conf.set('DESKTOP_DIR', '"@0@"'.format(join_paths(rygel_datadir, 'applications')))
config_include = include_directories('.')

add_global_arguments(['-include','config.h'], language : 'c')

vala = meson.get_compiler('vala')
gupnp = dependency('gupnp-1.0', version : '>= 0.24.14')
gee = dependency('gee-0.8', version: '>= 0.8.0')
gssdp = dependency('gssdp-1.0', version : '>= 0.13.0')
glib = dependency('glib-2.0', version : '>= 2.26')
gio = dependency('gio-2.0', version : '>= 2.26')
gio_unix = dependency('gio-unix-2.0', version : '>= 2.26')
gmodule = dependency('gmodule-2.0')
libxml = dependency('libxml-2.0', version: '>= 2.7')
gupnp_av = dependency('gupnp-av-1.0', version: '>= 0.12.8')
gupnp_dlna = dependency('gupnp-dlna-2.0', version: '>= 0.9.4')
gupnp_dlna_gst = dependency('gupnp-dlna-gst-2.0', version: '>= 0.9.4')
soup = dependency('libsoup-2.4', version : '>= 2.44.0')
mediaart = dependency('libmediaart-2.0', version : '>= 0.7.0')
sqlite = dependency('sqlite3', version : '>= 3.5')

gstreamer = dependency('gstreamer-1.0', version : '>= 1.0')
gstreamer_pbu = dependency('gstreamer-pbutils-1.0', version : '>= 1.0')
gstreamer_base = dependency('gstreamer-base-1.0', version : '>= 1.0')
gstreamer_audio = dependency('gstreamer-audio-1.0', version : '>= 1.0')
gstreamer_tag = dependency('gstreamer-tag-1.0', version : '>= 1.0')

gdk_pixbuf = dependency('gdk-pixbuf-2.0')
gtk = dependency('gtk+-3.0', version : '>= 3.0')

tracker_sparql = dependency('tracker-sparql-1.0')

posix = vala.find_library('posix')

sed = find_program('sed')
g_ir_compiler = find_program('g-ir-compiler')
gir_dir = join_paths(get_option('datadir'), 'gir-1.0')
typelib_dir = join_paths(get_option('libdir'), 'girepository-1.0')

cc = meson.get_compiler('c')
math = cc.find_library('m', required: false)
unistring = cc.find_library('unistring', required: false)
u8_strcoll_available = cc.has_function('u8_strcoll', dependencies: unistring)
if u8_strcoll_available
    conf.set('HAVE_UNISTRING', '1')
endif

common_deps = [gupnp, gee]

core_deps = common_deps + [gssdp, gio, gmodule, libxml, posix, math]
renderer_deps = common_deps + [gupnp_av, soup]
renderer_gst_deps = common_deps + [gstreamer, gstreamer_audio]
server_deps = common_deps + [gssdp, gupnp_av, soup, mediaart, gmodule, libxml]
db_deps = common_deps + [gupnp_av, gio, sqlite, unistring]
media_engine_gst_dep = [gee, gupnp_av, libxml, gio, gstreamer, gstreamer_pbu,
                        gstreamer_base, gupnp_dlna]
ruih_deps = common_deps
rygel_deps = common_deps

external_plugin_deps = [gio]
gst_launch_plugin_deps = [gstreamer]
lms_deps = [sqlite]
mx_export_deps = common_deps + [gio, gio_unix, gstreamer, gstreamer_pbu,
                                gupnp_dlna, gupnp_av, mediaart, gdk_pixbuf,
                                posix, gupnp_dlna_gst, gstreamer_tag, libxml,
                                soup]
mx_plugin_deps = common_deps + [gstreamer, gstreamer_pbu, gio_unix, gupnp_dlna]
tracker_plugin_deps = common_deps + [tracker_sparql]
ui_deps = common_deps + [gtk]

configure_file(output: 'config.h', configuration: conf)

subdir('src')
subdir('data')
subdir('doc')
