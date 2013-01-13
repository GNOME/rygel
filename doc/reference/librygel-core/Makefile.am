RYGEL_DOCBUILD_MODULE = rygel-core
if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-core/filelist.am

# Note that LIBRYGEL_CORE_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_CORE_VAPI_SOURCE_FILES) \
		$(LIBRYGEL_CORE_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-core/, $(VALA_SOURCE_FILES))

RYGEL_DOCBUILD_VALADOC_FLAGS = \
	$(LIBRYGEL_CORE_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_BUILD_CONFIG_VALAFLAGS) \
	--pkg uuid


RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS =
endif

include $(top_srcdir)/doc/reference/doc-build.am



