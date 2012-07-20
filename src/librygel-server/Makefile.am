include ../../common.am
include $(srcdir)/filelist.am

lib_LTLIBRARIES = librygel-server-1.0.la

LIBRYGEL_SERVER_VERSION=0:0:0

AM_CFLAGS += -DG_LOG_DOMAIN=\"Rygel\" \
	$(LIBGUPNP_DLNA_CFLAGS)

librygel_server_1_0_la_SOURCES = \
	$(LIBRYGEL_SERVER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_SERVER_NONVAPI_SOURCE_FILES)

librygel_server_1_0_la_VALAFLAGS = \
	-H rygel-server.h --library=rygel-server-1.0 \
	$(LIBRYGEL_SERVER_VALAFLAGS_PKG) \
	$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_server_1_0_la_LIBADD = $(RYGEL_COMMON_LIBS) \
	$(LIBGUPNP_DLNA_LIBS) \
	$(GST_PBU_LIBS)
librygel_server_1_0_la_LDFLAGS = -version-info $(LIBRYGEL_SERVER_VERSION)

rygel-server.h rygel-server-1.0.vapi: librygel_server_1_0_la_vala.stamp
