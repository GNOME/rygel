SUBDIRS = xml

schemadir = @GCONF_SCHEMA_FILE_DIR@
schema_DATA = rygel.schemas

shareddir = $(datadir)/rygel

if BUILD_UI
dist_shared_DATA = rygel-preferences.ui
endif

if GCONF_SCHEMAS_INSTALL
install-data-local: $(schema_DATA)
	GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) $(GCONFTOOL) --makefile-install-rule $(srcdir)/$(schema_DATA);
endif

# DBus service file
dbusservicedir = $(datadir)/dbus-1/services
dbusservice_in_files = org.gnome.Rygel.service.in
dbusservice_DATA = $(dbusservice_in_files:.service.in=.service)

# Rule to make the service file with bindir expanded
$(dbusservice_DATA): $(dbusservice_in_files) Makefile
	@sed -e "s|\@bindir\@|$(bindir)|" $< > $@

desktopdir = $(datadir)/applications
desktop_in_files = rygel-preferences.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)

# Rule to create the .desktop files
$(desktop_DATA): $(desktop_in_files) Makefile
	@sed -e "s,\$${prefix},${prefix},g" \
	     -e "s,\$${version},${PACKAGE_VERSION},g" \
             $(@:.desktop=.desktop.in) > $@

CLEANFILES = $(dbusservice_DATA) $(desktop_DATA)
EXTRA_DIST = $(schema_DATA) $(dbusservice_in_files) $(desktop_in_files)

MAINTAINERCLEANFILES = Makefile.in
