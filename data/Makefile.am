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

EXTRA_DIST = $(schema_DATA)

MAINTAINERCLEANFILES = Makefile.in
