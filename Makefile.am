SUBDIRS = src data

pkgconfig_DATA= rygel-1.0.pc
pkgconfigdir = $(libdir)/pkgconfig

EXTRA_DIST = rygel-1.0.pc.in \
             .version

DISTCHECK_CONFIGURE_FLAGS = --enable-gtk-doc

# Extra clean files so that maintainer-clean removes *everything*
MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub configure depcomp install-sh ltmain.sh Makefile.in missing config.h.in

ACLOCAL_AMFLAGS = -I m4

# see build-aux/git-version-get for details
BUILT_SOURCES = $(top_srcdir)/.version
$(top_srcdir)/.version:
	echo $(VERSION) > $@-t && mv $@-t $@
dist-hook:
	echo $(VERSION) > $(distdir)/.tarball-version
