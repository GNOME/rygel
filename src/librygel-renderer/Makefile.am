include ../../common.am
include $(srcdir)/filelist.am

librygel_renderer_includedir=$(includedir)/rygel-1.0
librygel_renderer_include_HEADERS = rygel-renderer.h

lib_LTLIBRARIES = librygel-renderer-1.0.la

LIBRYGEL_RENDERER_VERSION=0:0:0

librygel_renderer_1_0_la_SOURCES = \
	$(LIBRYGEL_RENDERER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES)

librygel_renderer_1_0_la_CFLAGS = \
	$(AM_CFLAGS) \
	$(LIBGSTREAMER_CFLAGS)

librygel_renderer_1_0_la_VALAFLAGS = \
	-H rygel-renderer.h --library=rygel-renderer-1.0 \
	$(LIBRYGEL_RENDERER_VALAFLAGS_PKG) \
	$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_renderer_1_0_la_LIBADD = $(RYGEL_COMMON_LIBS) $(LIBGSTREAMER_LIBS)
librygel_renderer_1_0_la_LDFLAGS = -version-info $(LIBRYGEL_RENDERER_VERSION)

vapidir = $(VAPIDIR)
vapi_DATA = rygel-renderer-1.0.vapi rygel-renderer-1.0.deps

rygel-renderer.h rygel-renderer-1.0.vapi: librygel_renderer_1_0_la_vala.stamp

EXTRA_DIST = rygel-renderer.h rygel-renderer-1.0.vapi rygel-renderer-1.0.deps
