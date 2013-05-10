include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygel_server_includedir=$(includedir)/rygel-2.0
librygel_server_include_HEADERS = rygel-server.h

lib_LTLIBRARIES = librygel-server-2.0.la

LIBRYGEL_SERVER_VERSION=1:0:0

librygel_server_2_0_la_SOURCES = \
	$(LIBRYGEL_SERVER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_SERVER_NONVAPI_SOURCE_FILES)

librygel_server_2_0_la_VALAFLAGS = \
	-H rygel-server.h --library=rygel-server-2.0 \
	$(LIBRYGEL_SERVER_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_server_2_0_la_CFLAGS = \
	$(LIBRYGEL_SERVER_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_CFLAGS) \
	-DENGINE_DIR='"$(enginedir)"' \
	-DG_LOG_DOMAIN=\"Rygel\"
librygel_server_2_0_la_LIBADD = \
	$(LIBRYGEL_SERVER_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_LIBS)

librygel_server_2_0_la_LDFLAGS = \
	$(RYGEL_DATA_DIR_DEFINES) \
	-version-info $(LIBRYGEL_SERVER_VERSION)

vapidir = $(VAPIDIR)
vapi_DATA = rygel-server-2.0.vapi rygel-server-2.0.deps

rygel-server.h rygel-server-2.0.vapi: librygel_server_2_0_la_vala.stamp

EXTRA_DIST = rygel-server.h rygel-server-2.0.vapi rygel-server-2.0.deps
