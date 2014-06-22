include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygelincdir = $(includedir)/rygel-2.4

librygelinc_HEADERS = rygel-core.h

lib_LTLIBRARIES = librygel-core-2.4.la

librygel_core_2_4_la_SOURCES = \
	$(LIBRYGEL_CORE_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_CORE_NONVAPI_SOURCE_FILES)

librygel_core_2_4_la_VALAFLAGS = \
	-H rygel-core.h -C --library=rygel-core-2.4 \
	--vapidir=$(srcdir) \
	--pkg uuid \
	--pkg posix \
	$(LIBRYGEL_CORE_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_core_2_4_la_CFLAGS = \
	$(RYGEL_COMMON_DEFINES_CFLAGS) \
	$(LIBRYGEL_CORE_DEPS_CFLAGS) \
	-DPLUGIN_DIR='"$(plugindir)"' \
	-DSMALL_ICON_DIR='"$(smallicondir)"' \
	-DBIG_ICON_DIR='"$(bigicondir)"' \
	-include config.h \
	-DG_LOG_DOMAIN='"Rygel"'

librygel_core_2_4_la_LIBADD = \
	$(LIBRYGEL_CORE_DEPS_LIBS) \
	-lm

RYGEL_CORE_VERSION=2:4:0
librygel_core_2_4_la_LDFLAGS = \
	$(RYGEL_DATA_DIR_DEFINES) \
	-version-info $(RYGEL_CORE_VERSION)

BUILT_SOURCES = \
	rygel-core-2.4.vapi \
	rygel-core.h

VAPI_FILES = rygel-core-2.4.vapi
DEPS_FILES = rygel-core-2.4.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)
rygel-core-2.4.vapi rygel-core.h: librygel_core_2_4_la_vala.stamp

MAINTAINERCLEANFILES += $(BUILT_SOURCES)

EXTRA_DIST = \
	rygel-build-config.vapi \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	uuid.vapi \
	$(BUILT_SOURCES)
