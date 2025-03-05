ui_resource = gnome.compile_resources(
    'preferences-ui-resources',
    meson.project_source_root() / 'data/org.gnome.Rygel.Preferences.gresource.xml',
    source_dir: [meson.project_source_root() / 'data']
)

rygel_preferences_sources = [
    'rygel-preferences-dialog.vala',
    'rygel-preferences-section.vala',
    'rygel-media-pref-section.vala',
    'rygel-writable-user-config.vala',
    'rygel-network-pref-section.vala',
    ui_resource
]


executable('rygel-preferences',
           rygel_preferences_sources,
           c_args : ['-DG_LOG_DOMAIN="RygelPreferences"'],
           dependencies : ui_deps + [build_config, rygel_core],
           install: true
)
