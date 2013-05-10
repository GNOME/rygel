include $(top_srcdir)/common.am

SUBDIRS = xml icons

sysconf_DATA = rygel.conf

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
desktop_in_files = rygel.desktop.in rygel-preferences.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

preset_DATA = $(srcdir)/presets/avenc_aac.prs \
	$(srcdir)/presets/avenc_mp2.prs \
	$(srcdir)/presets/avenc_mpeg2video.prs \
	$(srcdir)/presets/avenc_wmav1.prs \
	$(srcdir)/presets/avenc_wmv1.prs \
	$(srcdir)/presets/GstFaac.prs \
	$(srcdir)/presets/GstLameMP3Enc.prs \
	$(srcdir)/presets/GstMP4Mux.prs \
	$(srcdir)/presets/GstTwoLame.prs \
	$(srcdir)/presets/GstX264Enc.prs

CLEANFILES = $(dbusservice_DATA) $(desktop_DATA)
EXTRA_DIST = $(dbusservice_in_files) \
	     $(desktop_in_files) \
	     $(sysconf_DATA) \
	     $(pixmaps_DATA) \
	     $(preset_DATA)

