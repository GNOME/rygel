include ../../common.am
include $(srcdir)/filelist.am

librygel_renderer_includedir=$(includedir)/rygel-2.0
librygel_renderer_include_HEADERS = rygel-renderer-gst.h

lib_LTLIBRARIES = librygel-renderer-gst-2.0.la

LIBRYGEL_RENDERER_GST_VERSION=1:0:0

librygel_renderer_gst_2_0_la_SOURCES = \
	$(LIBRYGEL_RENDERER_GST_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_GST_NONVAPI_SOURCE_FILES)

AM_CFLAGS += -DG_LOG_DOMAIN=\"Rygel\" \
	$(LIBGSTREAMER_CFLAGS)

librygel_renderer_gst_2_0_la_VALAFLAGS = \
	-H rygel-renderer-gst.h --library=rygel-renderer-gst-2.0 \
	$(LIBRYGEL_RENDERER_GST_VALAFLAGS_PKG) \
	$(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)
librygel_renderer_gst_2_0_la_LIBADD = \
	$(RYGEL_COMMON_RENDERER_LIBS) \
	$(LIBGSTREAMER_LIBS) \
	$(LIBGUPNP_AV_LIBS)
librygel_renderer_gst_2_0_la_LDFLAGS = -version-info $(LIBRYGEL_RENDERER_GST_VERSION)

rygel-renderer-gst.h rygel-renderer-gst-2.0.vapi: \
	librygel_renderer_gst_2_0_la_vala.stamp

vapidir = $(VAPIDIR)
vapi_DATA = rygel-renderer-gst-2.0.vapi rygel-renderer-gst-2.0.deps

EXTRA_DIST=rygel-renderer-gst.h rygel-renderer-gst-2.0.vapi rygel-renderer-gst-2.0.deps
