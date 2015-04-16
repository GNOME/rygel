include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygel_db_includedir=$(includedir)/rygel-2.6
librygel_db_include_HEADERS = rygel-db.h

lib_LTLIBRARIES = librygel-db-2.6.la

LIBRYGEL_DB_VERSION=2:4:0

librygel_db_2_6_la_SOURCES = \
	$(LIBRYGEL_DB_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_DB_NONVAPI_SOURCE_FILES)

librygel_db_2_6_la_VALAFLAGS = \
	-H rygel-db.h --library=rygel-db-2.6 \
	$(LIBRYGEL_DB_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_db_2_6_la_CFLAGS = \
	$(LIBRYGEL_DB_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_CFLAGS) \
	-DENGINE_DIR='"$(enginedir)"' \
	-DG_LOG_DOMAIN=\"RygelDb\"
librygel_db_2_6_la_LIBADD = \
	$(LIBRYGEL_DB_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_LIBS)

librygel_db_2_6_la_LDFLAGS = \
	$(RYGEL_DATA_DIR_DEFINES) \
	-version-info $(LIBRYGEL_DB_VERSION)

vapidir = $(VAPIDIR)
vapi_DATA = rygel-db-2.6.vapi rygel-db-2.6.deps

rygel-db.h rygel-db-2.6.vapi: librygel_db_2_6_la_vala.stamp

DISTCLEANFILES = $(nodist_typelib_DATA)
EXTRA_DIST = rygel-db.h rygel-db-2.6.vapi rygel-db-2.6.deps
