include $(top_srcdir)/common.am

bin_PROGRAMS = rygel
libexec_PROGRAMS = rygel-acl-provider

rygel_SOURCES = \
	rygel-acl.vala \
	rygel-dbus-service.vala \
	rygel-main.vala

rygel_VALAFLAGS = \
	--pkg posix \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

rygel_CFLAGS = \
	$(RYGEL_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-include config.h \
	-DLOCALEDIR=\""$(datadir)/locale"\" \
	-DG_LOG_DOMAIN='"Rygel"' \
	-DSYS_CONFIG_DIR='"$(sysconfigdir)"'

rygel_LDADD = \
	$(RYGEL_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)

rygel_acl_provider_SOURCES = \
	acl-provider.vala \
	acl-store.vala

rygel_acl_provider_VALAFLAGS = \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

rygel_acl_provider_CFLAGS = \
	$(RYGEL_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_CFLAGS) \
	-include config.h \
	-DLOCALEDIR=\""$(datadir)/locale"\" \
	-DG_LOG_DOMAIN='"RygelAcl"' \
	-DSYS_CONFIG_DIR='"$(sysconfigdir)"'

rygel_acl_provider_LDADD = \
	$(RYGEL_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_LIBS)


vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

MAINTAINERCLEANFILES += $(BUILT_SOURCES)

EXTRA_DIST = \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(BUILT_SOURCES)

