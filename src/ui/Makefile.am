include $(top_srcdir)/common.am

bin_PROGRAMS = rygel-preferences

rygel_preferences_SOURCES =  \
	rygel-preferences-dialog.vala \
	rygel-preferences-section.vala \
	rygel-media-pref-section.vala \
	rygel-writable-user-config.vala \
	rygel-network-pref-section.vala \
	rygel-user-config.vala

rygel_preferences_VALAFLAGS = \
	$(RYGEL_UI_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

rygel_preferences_CFLAGS = \
	$(RYGEL_UI_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_CFLAGS) \
	-DSMALL_ICON_DIR='"$(icondir)"' \
	-DLOCALEDIR=\""$(datadir)/locale"\" \
	-DG_LOG_DOMAIN='"Rygel"' \
	-DDESKTOP_DIR='"$(desktopdir)"' \
	-DSYS_CONFIG_DIR='"$(sysconfigdir)"'
rygel_preferences_LDADD = \
	$(RYGEL_UI_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_CORE_LIBS)
rygel_preferences_LDFLAGS = \
	$(RYGEL_DATA_DIR_DEFINES) \
	-export-dynamic
