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

# systemd service file
systemdservicedir = $(systemduserunitdir)
systemdservice_in_files = rygel.service.in
systemdservice_DATA = rygel.service

# Rule to make the systemd service file with bindir expanded
$(systemdservice_DATA): rygel.service.in Makefile
	$(AM_V_GEN) $(SED) -e "s|\@bindir\@|$(bindir)|" $< > $@

# Rule to create the .desktop files
desktop_in_files = $(srcdir)/rygel.desktop.in $(srcdir)/rygel-preferences.desktop.in
desktop_DATA = rygel.desktop rygel-preferences.desktop

%.desktop.in : %.desktop.in.in
	$(AM_V_GEN) sed -e 's|@VERSION[@]|$(VERSION)|g' $< > $@

%.desktop : %.desktop.in
	$(AM_V_GEN) $(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

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

CLEANFILES = $(dbusservice_DATA) $(desktop_DATA) $(systemdservice_DATA)
EXTRA_DIST = $(dbusservice_in_files) \
	     $(desktop_in_files) \
		 rygel.desktop.in.in rygel-preferences.desktop.in.in \
	     $(sysconf_DATA) \
	     $(pixmaps_DATA) \
	     $(preset_DATA) \
	     $(systemdservice_in_files)
