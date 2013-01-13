RYGEL_DOCBUILD_MODULE = rygel-renderer
if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-renderer/filelist.am

# Note that LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_RENDERER_VAPI_SOURCE_FILES) \
	$(LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-renderer/, $(VALA_SOURCE_FILES))

# TODO: The need for rygel-build-config here reminds us that we shouldn't need that in librygel-renderer either.
RYGEL_DOCBUILD_VALADOC_FLAGS = \
	$(LIBRYGEL_RENDERER_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_BUILD_CONFIG_VALAFLAGS)

RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS = -X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-2.0.so

RYGEL_GTKDOC_DOCS_XML_EXTRA = $(top_srcdir)/doc/reference/lib$(RYGEL_DOCBUILD_MODULE)/gtkdoc/implementing-renderer-plugins.xml \
		$(top_srcdir)/doc/reference/lib$(RYGEL_DOCBUILD_MODULE)/gtkdoc/implementing-renderers.xml

endif

include $(top_srcdir)/doc/reference/doc-build.am



