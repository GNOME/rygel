include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-lms.la
plugin_DATA = lms.plugin

librygel_lms_la_SOURCES = \
	rygel-lms-plugin.vala \
	rygel-lms-plugin-factory.vala \
	rygel-lms-root-container.vala \
	rygel-lms-music-root.vala \
	rygel-lms-image-root.vala \
	rygel-lms-category-container.vala \
	rygel-lms-all-music.vala \
	rygel-lms-album.vala \
	rygel-lms-albums.vala \
	rygel-lms-artist.vala \
	rygel-lms-artists.vala \
	rygel-lms-all-videos.vala \
	rygel-lms-database.vala \
	rygel-lms-all-images.vala \
	rygel-lms-image-years.vala \
	rygel-lms-image-year.vala \
	rygel-lms-sql-function.vala \
	rygel-lms-sql-operator.vala \
	rygel-lms-collate.c \
	rygel-lms-dbus-interfaces.vala

librygel_lms_la_VALAFLAGS = \
	--enable-experimental \
	$(RYGEL_PLUGIN_LMS_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)

librygel_lms_la_CFLAGS = \
	$(RYGEL_PLUGIN_LMS_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"Lms"'

librygel_lms_la_LIBADD = \
	$(RYGEL_PLUGIN_LMS_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)

librygel_lms_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = lms.plugin.in
