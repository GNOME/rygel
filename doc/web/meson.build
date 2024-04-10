fs = import('fs')
python = import('python')

sphinx = find_program('sphinx-build', required: false, disabler: true)

# fixme: Need to look for furo theme as well

docs_rst = [
  'index.rst',
  'development.rst',
  'architecture.rst',
  'coding-style.rst',
  'faq.rst',
  'troubleshooting.rst',
  'plugins.rst',
  'integration.rst',
  'system-integration.rst',
  'media-server2.rst',
]

custom_target('docs',
  input: docs_rst,
  depend_files: ['conf.py'],
  output: 'docs',
  build_always_stale: true,
  command: [
    sphinx,
    '-n', '-b', 'html', '-q',
    '-c', meson.current_source_dir(),
    '-Drelease=' + meson.project_version(),
    meson.current_source_dir(),
    '@OUTPUT@'])
