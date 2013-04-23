include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-tracker.la
plugin_DATA = tracker.plugin

librygel_tracker_la_SOURCES = \
	rygel-tracker-root-container.vala \
	rygel-tracker-category-container.vala \
	rygel-tracker-music.vala \
	rygel-tracker-videos.vala \
	rygel-tracker-pictures.vala \
	rygel-tracker-metadata-values.vala \
	rygel-tracker-metadata-container.vala \
	rygel-tracker-metadata-multivalues.vala \
	rygel-tracker-tags.vala \
	rygel-tracker-years.vala \
	rygel-tracker-titles.vala \
	rygel-tracker-albums.vala \
	rygel-tracker-artists.vala \
	rygel-tracker-genre.vala \
	rygel-tracker-new.vala \
	rygel-tracker-search-container.vala \
	rygel-tracker-category-all-container.vala \
	rygel-tracker-upnp-property-map.vala \
	rygel-tracker-query.vala \
	rygel-tracker-selection-query.vala \
	rygel-tracker-deletion-query.vala \
	rygel-tracker-insertion-query.vala \
	rygel-tracker-cleanup-query.vala \
	rygel-tracker-query-triplet.vala \
	rygel-tracker-query-triplets.vala \
	rygel-tracker-item-factory.vala \
	rygel-tracker-video-item-factory.vala \
	rygel-tracker-music-item-factory.vala \
	rygel-tracker-picture-item-factory.vala \
	rygel-tracker-plugin.vala \
	rygel-tracker-plugin-factory.vala \
	rygel-tracker-interfaces.vala

librygel_tracker_la_VALAFLAGS = \
	--pkg posix \
	$(RYGEL_PLUGIN_TRACKER_DEPS_VALAFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_VALAFLAGS) \
	$(RYGEL_COMMON_VALAFLAGS)
librygel_tracker_la_CFLAGS = \
	$(RYGEL_PLUGIN_TRACKER_DEPS_CFLAGS) \
	$(TRACKER_SPARQL_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS) \
	-DG_LOG_DOMAIN='"Rygel-Tracker"'
librygel_tracker_la_LIBADD = \
	$(RYGEL_PLUGIN_TRACKER_DEPS_LIBS) \
	$(TRACKER_SPARQL_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)
librygel_tracker_la_LDFLAGS = \
	$(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = tracker.plugin.in
