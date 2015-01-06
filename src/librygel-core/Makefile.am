include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygelincdir = $(includedir)/rygel-2.6

librygelinc_HEADERS = rygel-core.h

lib_LTLIBRARIES = librygel-core-2.6.la

librygel_core_2_6_la_SOURCES = \
	$(LIBRYGEL_CORE_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_CORE_NONVAPI_SOURCE_FILES)

librygel_core_2_6_la_VALAFLAGS = \
	-H rygel-core.h -C --library=rygel-core-2.6 \
	--gir=Rygel-2.6.gir \
	--vapidir=$(srcdir) \
	--pkg uuid \
	$(LIBRYGEL_CORE_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_core_2_6_la_CFLAGS = \
	$(RYGEL_COMMON_DEFINES_CFLAGS) \
	$(LIBRYGEL_CORE_DEPS_CFLAGS) \
	-DPLUGIN_DIR='"$(plugindir)"' \
	-DSMALL_ICON_DIR='"$(smallicondir)"' \
	-DBIG_ICON_DIR='"$(bigicondir)"' \
	-include config.h \
	-DG_LOG_DOMAIN='"RygelCore"'

librygel_core_2_6_la_LIBADD = \
	$(LIBRYGEL_CORE_DEPS_LIBS) \
	-lm

RYGEL_CORE_VERSION=2:4:0
librygel_core_2_6_la_LDFLAGS = \
	$(RYGEL_DATA_DIR_DEFINES) \
	-version-info $(RYGEL_CORE_VERSION)

BUILT_SOURCES = \
	rygel-core-2.6.vapi \
	rygel-core.h

VAPI_FILES = rygel-core-2.6.vapi
DEPS_FILES = rygel-core-2.6.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)
rygel-core-2.6.vapi rygel-core.h Rygel-2.6.gir: librygel_core_2_6_la_vala.stamp

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS=
INTROSPECTION_SCANNER_ARGS=
INTROSPECTION_COMPILER_ARGS= -l librygel-core-2.6.so.2
if HAVE_INTROSPECTION
$(builddir)/RygelCore-2.6.gir: $(srcdir)/Rygel-2.6.gir
	$(AM_V_GEN)$(SED) -e 's,Rygel\.,RygelCore.,g' -e 's,namespace name="Rygel",namespace name="RygelCore",g' $< >$@
GIRS = RygelCore-2.6.gir

girdir=$(datadir)/gir-1.0
dist_gir_DATA = $(GIRS)

typelibdir = $(libdir)/girepository-1.0
nodist_typelib_DATA = $(GIRS:.gir=.typelib)

endif

MAINTAINERCLEANFILES += $(BUILT_SOURCES)

DISTCLEANFILES = $(nodist_typelib_DATA)

EXTRA_DIST = \
	rygel-build-config.vapi \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	uuid.vapi \
	$(BUILT_SOURCES) \
	RygelCore-2.6.gir \
	Rygel-2.6.gir
