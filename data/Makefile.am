SUBDIRS = xml icons

sysconf_DATA = rygel.conf

shareddir = $(datadir)/rygel

if BUILD_UI
dist_shared_DATA = rygel-preferences.ui
endif

# DBus service file
dbusservicedir = $(datadir)/dbus-1/services
dbusservice_in_files = org.gnome.Rygel1.service.in
dbusservice_DATA = $(dbusservice_in_files:.service.in=.service)

# Rule to make the service file with bindir expanded
$(dbusservice_DATA): $(dbusservice_in_files) Makefile
	@sed -e "s|\@bindir\@|$(bindir)|" $< > $@

# Rule to create the .desktop files
desktopdir = $(datadir)/applications
desktop_in_files = rygel.desktop.in rygel-preferences.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

CLEANFILES = $(dbusservice_DATA) $(desktop_DATA)
EXTRA_DIST = $(dbusservice_in_files) \
	     $(desktop_in_files) \
	     $(sysconf_DATA) \
	     $(pixmaps_DATA)


MAINTAINERCLEANFILES = Makefile.in
