rst2man = find_program ('rst2man', 'rst2man.py',
  required: get_option('man-pages'),
  disabler: true
)

rygel_conf_man_rst = custom_target('rygel.conf.rst',
  input: [meson.project_source_root() / 'build-aux/generate-conf-artifacts.py', meson.project_source_root() / 'data/configuration.yaml'],
  depend_files: [meson.project_source_root() / 'build-aux/generate-conf-artifacts.py', meson.project_source_root() / 'data/configuration.yaml'],
  output: 'rygel.conf.rst',
  command: [python, '@INPUT@', '-mman', '@OUTPUT@'],
  install: false,
)

custom_target('rygel manpage',
  input: 'rygel.rst',
  output: 'rygel.1',
  command: [rst2man, '@INPUT@', '@OUTPUT@'],
  install: true,
  install_dir: get_option('mandir') / 'man1'
)

custom_target('rygel.conf manpage',
  input: rygel_conf_man_rst,
  output: 'rygel.conf.5',
  command: [rst2man, '@INPUT@', '@OUTPUT@'],
  install: true,
  install_dir: get_option('mandir') / 'man5'
)

