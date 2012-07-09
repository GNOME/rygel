if ENABLE_VALADOC

include $(top_srcdir)/common.am
include $(top_srcdir)/src/librygel-server/filelist.am

# Note that LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES all (should) use the internal keyword
# so they are not shown as part of the public API.
VALA_SOURCE_FILES = $(LIBRYGEL_RENDERER_VAPI_SOURCE_FILES)
# There are no LIBRYGEL_RENDERER_NONVAPI_SOURCE_FILES

VALA_SOURCE_FILES_WITH_PATHS = $(addprefix $(top_srcdir)/src/librygel-server/, $(VALA_SOURCE_FILES))

#debug:
#	echo $(VALA_SOURCE_FILES_WITH_PATHS);

# TODO: The need for rygel-build-config here reminds us that we shouldn't need that in librygel-server either.
# TODO: Why is gstreamer-pbutils-0.10 needed here, but not needed in librygel-server/Makefile.am?
VALADOC_FLAGS = --force \
		--vapidir $(top_srcdir)/src/librygel-core \
		--pkg rygel-core-1.0 \
		--vapidir $(top_srcdir)/src/librygel-server \
		$(RYGEL_COMMON_VALAFLAGS_PKG) \
		$(LIBRYGEL_RENDERER_VALAFLAGS_PKG) \
	        --pkg gstreamer-pbutils-0.10 \
	        --target-glib=2.32 \
	        --vapidir=$(rygeldir) \
	        --pkg rygel-build-config \
		-b $(top_srcdir)/src/librygel-server \
		--package-name librygel-server \
		--package-version 1.0 \
		$(VALA_SOURCE_FILES_WITH_PATHS)

valadoc: $(VALA_SOURCE_FILES_WITH_PATHS)
	$(AM_V_GEN)$(VALADOC) \
		-o valadoc \
		$(VALADOC_FLAGS) 2>/dev/null

gtkdoc: $(VALA_SOURCE_FILES_WITH_PATHS)
	@rm -rf gtkdoc
	$(AM_V_GEN)$(VALADOC) \
		-X $(top_builddir)/src/librygel-server/rygel-server.h \
		-X -l -X $(top_builddir)/src/librygel-server/.libs/librygel-server-1.0.so \
		-o gtkdoc \
		--doclet gtkdoc \
		$(VALADOC_FLAGS) 2>/dev/null

clean-local:
	rm -rf valadoc gtkdoc

uninstall-hook:
	rm -rf $(DESTDIR)$(datadir)/gtk-doc/html/librygel-server

# The chmod corrects the directory permissions so that distcheck can remove the installed files.
install-data-hook: gtkdoc
	cp -d -R $(srcdir)/gtkdoc/html $(DESTDIR)$(datadir)/gtk-doc/html/librygel-server
	chmod -R u+w $(DESTDIR)$(datadir)/gtk-doc/html/librygel-server

all: valadoc gtkdoc

EXTRA_DIST = gtkdoc valadoc

endif
