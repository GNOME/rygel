db_sources = files(
    'database-cursor.vala',
    'database.vala',
    'sql-function.vala',
    'sql-operator.vala',
    'collate.c'
)

db_lib = library('rygel-db-2.8', db_sources,
        dependencies : db_deps + [rygel_core],
        include_directories: [config_include, include_directories('.')],
        version: lib_version,
        darwin_versions: darwin_versions,
        c_args : ['-DG_LOG_DOMAIN="RygelDb"'],
        vala_header : 'rygel-db.h',
        install: true,
        install_dir : [true, rygel_includedir, true])
install_data('rygel-db-2.8.deps', install_dir : rygel_vapidir)

# need to add to get the current build dir as include dir
rygel_db = declare_dependency(include_directories: include_directories('.'),
                                dependencies: db_deps,
                                link_with: db_lib)
