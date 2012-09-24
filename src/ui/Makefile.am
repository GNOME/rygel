include ../../common.am

AM_CFLAGS += \
	$(GTK_CFLAGS) \
	-DSMALL_ICON_DIR='"$(icondir)"' \
	-DLOCALEDIR=\""$(datadir)/locale"\" -DG_LOG_DOMAIN='"Rygel"'

bin_PROGRAMS = rygel-preferences

rygel_preferences_SOURCES =  \
	rygel-preferences-dialog.vala \
	rygel-preferences-section.vala \
	rygel-media-pref-section.vala \
	rygel-writable-user-config.vala \
	rygel-network-pref-section.vala \
	rygel-user-config.vala

rygel_preferences_VALAFLAGS = \
	--pkg gio-2.0 \
	--pkg gtk+-3.0 $(RYGEL_COMMON_PLUGIN_VALAFLAGS)

rygel_preferences_LDADD = \
	$(RYGEL_COMMON_LIBS) \
	$(LIBGSSDP_LIBS) \
	$(GTK_LIBS)
rygel_preferences_LDFLAGS = -export-dynamic

