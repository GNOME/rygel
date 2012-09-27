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
	--package-version 1.0 \
	$(VALA_SOURCE_FILES_WITH_PATHS)

valadoc: $(VALA_SOURCE_FILES_WITH_PATHS)
	$(AM_V_GEN)$(VALADOC) \
		-o valadoc \
		$(VALADOC_FLAGS)

gtkdoc: $(VALA_SOURCE_FILES_WITH_PATHS)
	@rm -rf gtkdoc
	$(AM_V_GEN)$(VALADOC) \
		-X $(top_srcdir)/src/librygel-core/rygel-core.h \
		-X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-1.0.so \
		-o gtkdoc \
		--doclet gtkdoc \
		$(VALADOC_FLAGS)

clean-local:
	rm -rf valadoc gtkdoc

uninstall-hook:
	rm -rf $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core

# The chmod corrects the directory permissions so that distcheck can remove the installed files.
install-data-hook: gtkdoc
	$(MKDIR_P) $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core
	cp -d -R $(srcdir)/gtkdoc/html $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core
	chmod -R u+w $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core

all: valadoc gtkdoc

EXTRA_DIST = gtkdoc valadoc

endif
