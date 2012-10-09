if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-core/filelist.am

# Note that LIBRYGEL_CORE_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_CORE_VAPI_SOURCE_FILES) \
		$(LIBRYGEL_CORE_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-core/, $(VALA_SOURCE_FILES))

VALADOC_FLAGS = --force \
	--vapidir $(top_srcdir)/src/librygel-core \
	$(RYGEL_COMMON_VALAFLAGS_PKG) \
	$(LIBRYGEL_CORE_VALAFLAGS_PKG) \
	--pkg gio-2.0 \
	--target-glib=2.32 \
	--vapidir=$(rygeldir) \
	--pkg rygel-build-config \
	-b $(top_srcdir)/src/librygel-core \
	--package-name librygel-core \
	--package-version 2.0 \
	$(VALA_SOURCE_FILES_WITH_PATHS)

RYGEL_DOCBUILD_MODULE = rygel-core
RYGEL_DOCBUILD_EXTRA_GTKDOC_OPTIONS =
endif

include $(top_srcdir)/doc/reference/doc-build.am



