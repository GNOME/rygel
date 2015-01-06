include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygel_server_includedir=$(includedir)/rygel-2.6
librygel_server_include_HEADERS = rygel-server.h

lib_LTLIBRARIES = librygel-server-2.6.la

LIBRYGEL_SERVER_VERSION=2:4:0

librygel_server_2_6_la_SOURCES = \
	$(LIBRYGEL_SERVER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_SERVER_NONVAPI_SOURCE_FILES)

librygel_server_2_6_la_VALAFLAGS = \
	-H rygel-server.h --library=rygel-server-2.6 \
	--gir=Rygel-2.6.gir \
	$(LIBRYGEL_SERVER_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_server_2_6_la_CFLAGS = \
	$(LIBRYGEL_SERVER_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_CFLAGS) \
	-DENGINE_DIR='"$(enginedir)"' \
	-DG_LOG_DOMAIN=\"RygelServer\"
librygel_server_2_6_la_LIBADD = \
	$(LIBRYGEL_SERVER_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_LIBS)

librygel_server_2_6_la_LDFLAGS = \
	$(RYGEL_DATA_DIR_DEFINES) \
	-version-info $(LIBRYGEL_SERVER_VERSION)

vapidir = $(VAPIDIR)
vapi_DATA = rygel-server-2.6.vapi rygel-server-2.6.deps

rygel-server.h rygel-server-2.6.vapi Rygel-2.6.gir: librygel_server_2_6_la_vala.stamp

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS=
INTROSPECTION_SCANNER_ARGS=
INTROSPECTION_COMPILER_ARGS= -l librygel-server-2.6.so.2 --includedir=$(builddir)/../librygel-core --includedir=$(srcdir)/../librygel-core
if HAVE_INTROSPECTION
$(builddir)/RygelServer-2.6.gir: $(srcdir)/Rygel-2.6.gir
	$(AM_V_GEN)$(SED) -e 's,Rygel\.,RygelServer.,g' \
		-e 's,namespace name="Rygel",namespace name="RygelServer",g' \
		-e 's,RygelServer\.Plugin,RygelCore.Plugin,g' \
		-e 's,RygelServer\.MediaDevice,RygelCore.MediaDevice,g' \
		-e 's,<package name="rygel-server-2.6"/>,<include name="RygelCore" version="2.6"/>\n<package name="rygel-server-2.6"/>,' \
		$< >$@
GIRS = RygelServer-2.6.gir

girdir=$(datadir)/gir-1.0
dist_gir_DATA = $(GIRS)

typelibdir = $(libdir)/girepository-1.0
nodist_typelib_DATA = $(GIRS:.gir=.typelib)

endif

DISTCLEANFILES = $(nodist_typelib_DATA)
EXTRA_DIST = rygel-server.h rygel-server-2.6.vapi rygel-server-2.6.deps RygelServer-2.6.gir Rygel-2.6.gir
