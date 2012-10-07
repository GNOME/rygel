include ../../common.am

AM_CFLAGS += \
	$(LIBGUPNP_DLNA_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS) \
	$(GST_PBU_CFLAGS) \
	-DSMALL_ICON_DIR='"$(smallicondir)"' \
	-DBIG_ICON_DIR='"$(bigicondir)"' -include config.h \
	-DLOCALEDIR=\""$(datadir)/locale"\" -DG_LOG_DOMAIN='"Rygel"'

bin_PROGRAMS = rygel

rygel_SOURCES = \
	rygel-dbus-service.vala \
	rygel-main.vala \
	$(top_builddir)/src/librygel-core/rygel-core-1.0.vapi

rygel_VALAFLAGS = \
	--pkg posix \
	--pkg gstreamer-0.10 \
	$(RYGEL_COMMON_VALAFLAGS)

rygel_LDADD = \
	$(top_builddir)/src/librygel-core/librygel-core-1.0.la \
	$(LIBGSSDP_LIBS) \
	$(RYGEL_BASE_LIBS)

rygel_LDFLAGS = -export-dynamic

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

MAINTAINERCLEANFILES += $(BUILT_SOURCES)

EXTRA_DIST = \
	rygel-build-config.vapi \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(BUILT_SOURCES)

