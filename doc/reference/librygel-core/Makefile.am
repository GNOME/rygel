if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-core/filelist.am

# Note that LIBRYGEL_CORE_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_CORE_VAPI_SOURCE_FILES) \
		$(LIBRYGEL_CORE_NONVAPI_SOURCE_FILES)

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-core/, $(VALA_SOURCE_FILES))

# TODO: The need for rygel-build-config here reminds us that we shouldn't need that in librygel-core either.
# TODO: Why is gstreamer-pbutils-0.10 needed here, but not needed in librygel-core/Makefile.am?
VALADOC_FLAGS = --force \
		--vapidir $(top_srcdir)/src/librygel-core \
		$(RYGEL_COMMON_VALAFLAGS_PKG) \
		$(LIBRYGEL_CORE_VALAFLAGS_PKG) \
	        --pkg gstreamer-pbutils-0.10 \
	        --target-glib=2.32 \
	        --vapidir=$(rygeldir) \
	        --pkg rygel-build-config \
		-b $(top_srcdir)/src/librygel-core \
		--package-name librygel-core \
		--package-version 1.0 \
		$(VALA_SOURCE_FILES_WITH_PATHS)

valadoc: $(VALA_SOURCE_FILES_WITH_PATHS)
	$(VALADOC) \
		-o valadoc \
		$(VALADOC_FLAGS) \
		$(NULL)

devhelp: $(VALA_SOURCE_FILES_WITH_PATHS)
	@rm -rf devhelp
	$(VALADOC) \
		-o devhelp \
		--doclet devhelp \
		$(VALADOC_FLAGS) \
		$(NULL)

gtkdoc: $(VALA_SOURCE_FILES_WITH_PATHS)
	@rm -rf gtkdoc
	$(VALADOC) \
		-X $(top_builddir)/src/librygel-core/rygel-core.h \
		-X -l -X $(top_builddir)/src/librygel-core/.libs/librygel-core-1.0.so \
		-o gtkdoc \
		--doclet gtkdoc \
		$(VALADOC_FLAGS) \
		$(NULL)

clean-local:
	rm -rf valadoc devhelp gtkdoc

uninstall-hook:
	rm -rf $(DESTDIR)$(datadir)/devhelp/books/librygel-core
	rm -rf $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core

# The chmod corrects the directory permissions so that distcheck can remove the installed files.
install-data-hook: devhelp gtkdoc
	$(MKDIR_P) $(DESTDIR)$(datadir)/devhelp/books/librygel-core/img
	$(INSTALL_DATA) -t $(DESTDIR)$(datadir)/devhelp/books/librygel-core $(srcdir)/devhelp/librygel-core/*.*
	$(INSTALL_DATA) -t $(DESTDIR)$(datadir)/devhelp/books/librygel-core/img $(srcdir)/devhelp/librygel-core/img/*
	$(MKDIR_P) $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core
	cp -d -R $(srcdir)/gtkdoc/html $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core
	chmod -R u+w $(DESTDIR)$(datadir)/gtk-doc/html/librygel-core

all: valadoc devhelp gtkdoc

EXTRA_DIST = devhelp gtkdoc valadoc

endif
