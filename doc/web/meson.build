fs = import('fs')

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
  'configuration.rst',
]

# Sphinx only allows to specify one source folder
# but we generate parts of the documentation so we copy all
# the other files to the build folder as well and use that as source below

doc_rst_deps = []

foreach doc : docs_rst
  doc_rst_deps += fs.copyfile(doc)
endforeach
subdir('img')

config_file_rst = custom_target('config-file.rst',
  input: [meson.project_source_root() / 'build-aux/generate-conf-artifacts.py', meson.project_source_root() / 'data/configuration.yaml'],
  depend_files: [meson.project_source_root() / 'build-aux/generate-conf-artifacts.py', meson.project_source_root() / 'data/configuration.yaml'],
  output: 'config-file.rst',
  command: [python, '@INPUT@', '-mrst', '@OUTPUT@']
)

custom_target('docs',
  input: docs_rst,
  depend_files: ['conf.py'],
  depends: [config_file_rst] + doc_rst_deps,
  output: 'docs',
  build_always_stale: true,
  command: [
    sphinx,
    '-n', '-b', 'html',
    '-c', meson.current_source_dir(),
    '-Drelease=' + meson.project_version(),
    meson.current_build_dir(),
    '@OUTPUT@'])
