if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-renderer-gst/filelist.am

# Note that LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_RENDERER_GST_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_GST_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-renderer-gst/, $(VALA_SOURCE_FILES))

#debug:
#	echo $(VALA_SOURCE_FILES_WITH_PATHS);

# TODO: The need for rygel-build-config here reminds us that we shouldn't need that in librygel-renderer-gst either.
# TODO: Why is gstreamer-pbutils-0.10 needed here, but not needed in librygel-renderer-gst/Makefile.am?
VALADOC_FLAGS = --force \
		--vapidir $(top_srcdir)/src/librygel-core \
		--pkg rygel-core-2.0 --pkg rygel-renderer-2.0 \
		--vapidir $(top_srcdir)/src/librygel-renderer-gst \
		--vapidir $(top_srcdir)/src/librygel-renderer \
		$(RYGEL_COMMON_VALAFLAGS_PKG) \
		$(LIBRYGEL_RENDERER_VALAFLAGS_PKG) \
	        --pkg gstreamer-pbutils-0.10 \
	        --target-glib=2.32 \
	        --vapidir=$(rygeldir) \
	        --pkg rygel-build-config \
		-b $(top_srcdir)/src/librygel-renderer-gst \
		--package-name librygel-renderer-gst \
		--package-version 2.0 \
		$(VALA_SOURCE_FILES_WITH_PATHS)

RYGEL_DOCBUILD_MODULE = rygel-renderer-gst
RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS = -X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-2.0.so
endif

include $(top_srcdir)/doc/reference/doc-build.am

