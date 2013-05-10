include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygel_renderer_includedir=$(includedir)/rygel-2.0
librygel_renderer_include_HEADERS = rygel-renderer.h

lib_LTLIBRARIES = librygel-renderer-2.0.la

LIBRYGEL_RENDERER_VERSION=1:0:0

librygel_renderer_2_0_la_SOURCES = \
	$(LIBRYGEL_RENDERER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES)

librygel_renderer_2_0_la_VALAFLAGS = \
	-H rygel-renderer.h --library=rygel-renderer-2.0 \
	$(LIBRYGEL_RENDERER_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_renderer_2_0_la_CFLAGS = \
	$(LIBRYGEL_RENDERER_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_CFLAGS) \
	-DG_LOG_DOMAIN=\"Rygel\"
librygel_renderer_2_0_la_LIBADD = \
	$(LIBRYGEL_RENDERER_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_LIBS)
librygel_renderer_2_0_la_LDFLAGS = \
	-version-info $(LIBRYGEL_RENDERER_VERSION)

vapidir = $(VAPIDIR)
vapi_DATA = rygel-renderer-2.0.vapi rygel-renderer-2.0.deps

rygel-renderer.h rygel-renderer-2.0.vapi: librygel_renderer_2_0_la_vala.stamp

EXTRA_DIST = rygel-renderer.h rygel-renderer-2.0.vapi rygel-renderer-2.0.deps
