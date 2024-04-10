conf_py = configure_file(input: 'conf.py.in', output: 'conf.py', configuration: pc_conf)

sphinx = find_program('sphinx-build', required: true, disabler: true)

docs_rst = [
  'index.rst',
  'development.rst',
]

custom_target('docs',
  input: docs_rst,
  depend_files: conf_py,
  output: 'docs',
  build_always_stale: true,
  command: [
    sphinx,
    '-n', '-b', 'html', '-q',
    '-c', meson.current_build_dir(),
    '-Drelease=' + meson.project_version(),
    meson.current_source_dir(),
    '@OUTPUT@'])
