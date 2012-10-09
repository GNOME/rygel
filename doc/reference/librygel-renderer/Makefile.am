if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-renderer/filelist.am

# Note that LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_RENDERER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-renderer/, $(VALA_SOURCE_FILES))

# TODO: The need for rygel-build-config here reminds us that we shouldn't need that in librygel-renderer either.
# TODO: Why is gstreamer-pbutils-0.10 needed here, but not needed in librygel-renderer/Makefile.am?
VALADOC_FLAGS = --force \
	--vapidir $(top_srcdir)/src/librygel-core \
	--pkg rygel-core-2.0 \
	--vapidir $(top_srcdir)/src/librygel-renderer \
	$(RYGEL_COMMON_VALAFLAGS_PKG) \
	$(LIBRYGEL_RENDERER_VALAFLAGS_PKG) \
	--target-glib=2.32 \
	--vapidir=$(rygeldir) \
	--pkg rygel-build-config \
	-b $(top_srcdir)/src/librygel-renderer \
	--package-name librygel-renderer \
	--package-version 2.0 \
	$(VALA_SOURCE_FILES_WITH_PATHS)

RYGEL_DOCBUILD_MODULE = rygel-renderer
RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS = -X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-2.0.so
endif

include $(top_srcdir)/doc/reference/doc-build.am



