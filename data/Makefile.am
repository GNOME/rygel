SUBDIRS = xml

if ENABLE_MAEMO
configfile = rygel-default.conf
else
configfile = rygel-maemo.conf
endif

sysconf_DATA = rygel.conf
$(sysconf_DATA): $(configfile) Makefile
	cp $(configfile) $@

shareddir = $(datadir)/rygel

if BUILD_UI
dist_shared_DATA = rygel-preferences.ui
endif

# DBus service file
dbusservicedir = $(datadir)/dbus-1/services
dbusservice_in_files = org.gnome.Rygel.service.in
dbusservice_DATA = $(dbusservice_in_files:.service.in=.service)

# Rule to make the service file with bindir expanded
$(dbusservice_DATA): $(dbusservice_in_files) Makefile
	@sed -e "s|\@bindir\@|$(bindir)|" $< > $@

desktopdir = $(datadir)/applications
desktop_in_files = rygel.desktop.in rygel-preferences.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

# Rule to create the .desktop files
$(desktop_DATA): $(desktop_in_files) Makefile
	@sed -e "s,\$${prefix},${prefix},g" \
	     -e "s,\$${version},${PACKAGE_VERSION},g" \
             $(srcdir)/$(@:.desktop=.desktop.in) > $@

CLEANFILES = $(dbusservice_DATA) $(desktop_DATA)
EXTRA_DIST = rygel-maemo.conf \
	     rygel-default.conf \
	     $(dbusservice_in_files) \
	     $(desktop_in_files)

MAINTAINERCLEANFILES = Makefile.in
