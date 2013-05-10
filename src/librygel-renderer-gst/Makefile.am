include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygel_renderer_includedir=$(includedir)/rygel-2.0
librygel_renderer_include_HEADERS = rygel-renderer-gst.h

lib_LTLIBRARIES = librygel-renderer-gst-2.0.la

LIBRYGEL_RENDERER_GST_VERSION=1:0:0

librygel_renderer_gst_2_0_la_SOURCES = \
	$(LIBRYGEL_RENDERER_GST_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_GST_NONVAPI_SOURCE_FILES)

librygel_renderer_gst_2_0_la_VALAFLAGS = \
	-H rygel-renderer-gst.h --library=rygel-renderer-gst-2.0 \
	--enable-experimental \
	$(LIBRYGEL_RENDERER_GST_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_renderer_gst_2_0_la_CFLAGS = \
	$(LIBRYGEL_RENDERER_GST_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_CFLAGS)
librygel_renderer_gst_2_0_la_LIBADD = \
	$(LIBRYGEL_RENDERER_GST_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_LIBS)
librygel_renderer_gst_2_0_la_LDFLAGS = \
	-version-info $(LIBRYGEL_RENDERER_GST_VERSION) \
	-DG_LOG_DOMAIN=\"Rygel\"

rygel-renderer-gst.h rygel-renderer-gst-2.0.vapi: \
	librygel_renderer_gst_2_0_la_vala.stamp

vapidir = $(VAPIDIR)
vapi_DATA = rygel-renderer-gst-2.0.vapi rygel-renderer-gst-2.0.deps

EXTRA_DIST=rygel-renderer-gst.h rygel-renderer-gst-2.0.vapi rygel-renderer-gst-2.0.deps
