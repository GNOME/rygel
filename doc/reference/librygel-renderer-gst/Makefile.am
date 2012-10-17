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
# TODO: Why is gstreamer-pbutils-0.10 needed here, but not needed in librygel-renderer-gst/Makefile.am?
RYGEL_DOCBUILD_VALADOC_FLAGS = \
		--vapidir $(top_srcdir)/src/librygel-core \
		--pkg rygel-core-2.0 \
		--vapidir $(top_srcdir)/src/librygel-renderer \
		--pkg rygel-renderer-2.0 \
	        --pkg gstreamer-pbutils-0.10 \
		$(RYGEL_COMMON_VALAFLAGS_PKG) \
		$(LIBRYGEL_RENDERER_GST_VALAFLAGS_PKG)

RYGEL_DOCBUILD_MODULE = rygel-renderer-gst
RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS = -X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-2.0.so \
                                      -X -l -X $(top_builddir)/src/librygel-renderer/.libs/librygel-renderer-2.0.so
RYGEL_GTKDOC_DOCS_XML_EXTRA = $(top_srcdir)/doc/reference/lib$(RYGEL_DOCBUILD_MODULE)/gtkdoc/example.xml

endif

include $(top_srcdir)/doc/reference/doc-build.am

