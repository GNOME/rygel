RYGEL_DOCBUILD_MODULE = rygel-renderer-gst
if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-renderer-gst/filelist.am

# Note that LIBRYGEL_RENDERER_GST_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_RENDERER_GST_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_GST_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-renderer-gst/, $(VALA_SOURCE_FILES))

#debug:
#	echo $(VALA_SOURCE_FILES_WITH_PATHS);

# TODO: The need for rygel-build-config here reminds us that we shouldn't need that in librygel-renderer-gst either.
RYGEL_DOCBUILD_VALADOC_FLAGS = \
		$(LIBRYGEL_RENDERER_GST_DEPS_VALAFLAGS) \
		$(RYGEL_COMMON_LIBRYGEL_RENDERER_VALAFLAGS)

RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS = -X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-2.0.so \
                                      -X -l -X $(top_builddir)/src/librygel-renderer/.libs/librygel-renderer-2.0.so
RYGEL_GTKDOC_DOCS_XML_EXTRA = $(top_srcdir)/doc/reference/lib$(RYGEL_DOCBUILD_MODULE)/gtkdoc/implementing-renderers-gst.xml

endif

include $(top_srcdir)/doc/reference/doc-build.am

