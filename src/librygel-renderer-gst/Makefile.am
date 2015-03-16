include $(top_srcdir)/common.am
include $(srcdir)/filelist.am

librygel_renderer_includedir=$(includedir)/rygel-2.6
librygel_renderer_include_HEADERS = rygel-renderer-gst.h

lib_LTLIBRARIES = librygel-renderer-gst-2.6.la

LIBRYGEL_RENDERER_GST_VERSION=2:4:0

librygel_renderer_gst_2_6_la_SOURCES = \
	$(LIBRYGEL_RENDERER_GST_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_GST_NONVAPI_SOURCE_FILES)

librygel_renderer_gst_2_6_la_VALAFLAGS = \
	-H rygel-renderer-gst.h --library=rygel-renderer-gst-2.6 \
	--gir=Rygel-2.6.gir \
	--enable-experimental \
	$(LIBRYGEL_RENDERER_GST_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_renderer_gst_2_6_la_CFLAGS = \
	$(LIBRYGEL_RENDERER_GST_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_CFLAGS)
librygel_renderer_gst_2_6_la_LIBADD = \
	$(LIBRYGEL_RENDERER_GST_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_LIBS)
librygel_renderer_gst_2_6_la_LDFLAGS = \
	-version-info $(LIBRYGEL_RENDERER_GST_VERSION) \
	-DG_LOG_DOMAIN=\"RygelRendererGst\"

rygel-renderer-gst.h rygel-renderer-gst-2.6.vapi Rygel-2.6.gir: librygel_renderer_gst_2_6_la_vala.stamp

vapidir = $(VAPIDIR)
vapi_DATA = rygel-renderer-gst-2.6.vapi rygel-renderer-gst-2.6.deps

-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS=
INTROSPECTION_SCANNER_ARGS=
INTROSPECTION_COMPILER_ARGS= -l librygel-renderer-gst-2.6.so.2 --includedir=$(builddir)/../librygel-core --includedir=$(srcdir)/../librygel-core --includedir=$(builddir)/../librygel-renderer --includedir=$(srcdir)/../librygel-renderer

if HAVE_INTROSPECTION
$(builddir)/RygelRendererGst-2.6.gir: $(srcdir)/Rygel-2.6.gir
	$(AM_V_GEN)$(SED) -e 's,Rygel\.,RygelRendererGst.,g' \
	-e 's,RygelRendererGst\.MediaRenderer,RygelRenderer.MediaRenderer,g' \
	-e 's,RygelRendererGst\.MediaPlayer,RygelRenderer.MediaPlayer,g' \
	-e 's,namespace name="Rygel",namespace name="RygelRendererGst",g' \
	-e 's,RygelRendererGst\.Plugin,RygelCore.Plugin,g' \
	-e 's,<package name="rygel-renderer-gst-2.6"/>,<include name="RygelCore" version="2.6"/>\n<include name="RygelRenderer" version="2.6"/>\n<package name="rygel-renderer-gst-2.6"/>,' \
	$< >$@
GIRS = RygelRendererGst-2.6.gir

girdir=$(datadir)/gir-1.0
dist_gir_DATA = $(GIRS)

typelibdir = $(libdir)/girepository-1.0
nodist_typelib_DATA = $(GIRS:.gir=.typelib)

endif

EXTRA_DIST=rygel-renderer-gst.h rygel-renderer-gst-2.6.vapi rygel-renderer-gst-2.6.deps RygelRendererGst-2.6.gir Rygel-2.6.gir
