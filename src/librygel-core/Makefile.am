include ../../common.am
include $(srcdir)/filelist.am

AM_CFLAGS += \
	$(LIBGUPNP_DLNA_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(GST_PBU_CFLAGS) \
	-DSMALL_ICON_DIR='"$(smallicondir)"' \
	-DBIG_ICON_DIR='"$(bigicondir)"' -include config.h \
	-DLOCALEDIR=\""$(datadir)/locale"\" -DG_LOG_DOMAIN='"Rygel"'

librygelincdir = $(includedir)/rygel-1.0

librygelinc_HEADERS = rygel-core.h

lib_LTLIBRARIES = librygel-core-1.0.la

librygel_core_1_0_la_SOURCES = \
	$(LIBRYGEL_CORE_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_CORE_NONVAPI_SOURCE_FILES)

librygel_core_1_0_la_VALAFLAGS = \
	-H rygel-core.h -C --library=rygel-core-1.0 \
	$(LIBRYGEL_CORE_VALAFLAGS_PKG) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_core_1_0_la_LIBADD = \
	$(GST_PBU_LIBS) \
	$(RYGEL_BASE_LIBS) \
	$(LIBGUPNP_DLNA_LIBS) \
	$(GIO_LIBS) \
	$(LIBSOUP_LIBS)

RYGEL_CORE_VERSION=0:0:0
librygel_core_1_0_la_LDFLAGS = -version-info $(RYGEL_CORE_VERSION)

BUILT_SOURCES = \
	rygel-core-1.0.vapi \
	rygel-core.h

VAPI_FILES = rygel-core-1.0.vapi
DEPS_FILES = rygel-core-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)
rygel-core-1.0.vapi rygel-core.h: librygel_core_1_0_la_vala.stamp

MAINTAINERCLEANFILES += $(BUILT_SOURCES)

EXTRA_DIST = \
	rygel-core-1.0.vapi \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(BUILT_SOURCES)
