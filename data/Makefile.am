SUBDIRS = pixmaps xml

shareddir = $(datadir)/gupnp-tools

dist_shared_DATA = $(srcdir)/gupnp-universal-cp.glade \
		   $(srcdir)/gupnp-network-light.glade \
		   $(srcdir)/gupnp-av-cp.glade

desktopdir = ${datadir}/applications
desktop_in_files = gupnp-universal-cp.desktop.in \
		   gupnp-av-cp.desktop.in \
		   gupnp-network-light.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

# Rule to create the .desktop files
$(desktop_DATA): $(desktop_in_files) Makefile
	@sed -e "s,\$${prefix},${prefix},g" $(@:.desktop=.desktop.in) > $@

EXTRA_DIST = $(desktop_in_files:.desktop.in=.desktop.in.in)

CLEANFILES = $(desktop_DATA)

MAINTAINERCLEANFILES = Makefile.in
