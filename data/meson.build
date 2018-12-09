install_data('rygel.conf', install_dir : rygel_sysconfdir)
install_data(join_paths('icons', '128x128', 'rygel.png'), install_dir : join_paths(rygel_icondir, '128x128', 'apps'))
install_data(join_paths('icons', '120x120', 'rygel.png'), install_dir : rygel_bigicondir)
install_data(join_paths('icons', '120x120', 'rygel.jpg'), install_dir : rygel_bigicondir)
install_data(join_paths('icons', '48x48', 'rygel.png'), install_dir : rygel_smallicondir)
install_data(join_paths('icons', '48x48', 'rygel.jpg'), install_dir : rygel_smallicondir)
install_data(join_paths('icons', '32x32', 'rygel.png'), install_dir : join_paths(rygel_icondir, '32x32', 'apps'))
install_data(join_paths('icons', '48x48', 'rygel.png'), install_dir : join_paths(rygel_icondir, '48x48', 'apps'))
install_data(join_paths('icons', 'scalable', 'rygel.svg'), install_dir : join_paths(rygel_icondir, 'scalable', 'apps'))
install_data(join_paths('icons', 'scalable', 'rygel-full.svg'), install_dir : join_paths(rygel_icondir, 'scalable', 'apps'))

install_data('rygel-preferences.ui', install_dir : rygel_datadir)

data_conf = configuration_data()
data_conf.set('bindir', join_paths(get_option('prefix'), get_option('bindir')))
data_conf.set('VERSION', meson.project_version())

configure_file(input: 'org.gnome.Rygel1.service.in',
               output: 'org.gnome.Rygel1.service',
               configuration: data_conf,
               install_dir : join_paths(
                   get_option('prefix'),
                   get_option('datadir'),
                   'dbus-1/services')
               )

systemd = dependency('systemd', required : false)
systemd_user_unit_dir = join_paths(get_option('prefix'), 'lib/systemd/user/')
if systemd.found()
    systemd_user_unit_dir = systemd.get_pkgconfig_variable('systemduserunitdir')
endif

if not (get_option('systemd-user-units-dir') == 'off')
    if not (get_option('systemd-user-units-dir') == 'auto')
        systemd_user_unit_dir = get_option('systemd-user-units-dir')
    endif

    configure_file(input: 'rygel.service.in',
                   output: 'rygel.service',
                   configuration: data_conf,
                   install_dir : systemd_user_unit_dir)
endif

rygel_desktop_preferences_in = configure_file(input: 'rygel-preferences.desktop.in.in',
               output : 'rygel-preferences.desktop.in',
               configuration : data_conf)

rygel_desktop_in = configure_file(input: 'rygel.desktop.in.in',
               output : 'rygel.desktop.in',
               configuration : data_conf)

i18n.merge_file(input: rygel_desktop_in,
                output: 'rygel.desktop',
                po_dir : join_paths('..','po'),
                type: 'desktop',
                install : true,
                install_dir: join_paths(get_option('datadir'), 'applications'))

i18n.merge_file(input: rygel_desktop_preferences_in,
                output: 'rygel-preferences.desktop',
                po_dir : join_paths('..','po'),
                type: 'desktop',
                install : true,
                install_dir: join_paths(get_option('datadir'), 'applications'))

subdir('presets')
subdir('xml')
