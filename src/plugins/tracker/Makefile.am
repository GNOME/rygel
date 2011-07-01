include ../../../common.am

plugin_LTLIBRARIES = librygel-tracker.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Tracker"' $(LIBGUPNP_DLNA_CFLAGS)

librygel_tracker_la_SOURCES = \
	rygel-tracker-root-container.vala \
	rygel-tracker-category-container.vala \
	rygel-tracker-music.vala \
	rygel-tracker-videos.vala \
	rygel-tracker-pictures.vala \
	rygel-tracker-metadata-values.vala \
	rygel-tracker-tags.vala \
	rygel-tracker-years.vala \
	rygel-tracker-titles.vala \
	rygel-tracker-albums.vala \
	rygel-tracker-artists.vala \
	rygel-tracker-genre.vala \
	rygel-tracker-new.vala \
	rygel-tracker-search-container.vala \
	rygel-tracker-category-all-container.vala \
	rygel-tracker-key-chain-map.vala \
	rygel-tracker-query.vala \
	rygel-tracker-selection-query.vala \
	rygel-tracker-deletion-query.vala \
	rygel-tracker-insertion-query.vala \
	rygel-tracker-cleanup-query.vala \
	rygel-tracker-query-triplet.vala \
	rygel-tracker-query-triplets.vala \
	rygel-tracker-query-filter.vala \
	rygel-tracker-logical-filter.vala \
	rygel-tracker-bound-filter.vala \
	rygel-tracker-regex-filter.vala \
	rygel-tracker-boolean-filter.vala \
	rygel-tracker-item-factory.vala \
	rygel-tracker-video-item-factory.vala \
	rygel-tracker-music-item-factory.vala \
	rygel-tracker-picture-item-factory.vala \
	rygel-tracker-plugin.vala \
	rygel-tracker-plugin-factory.vala \
	rygel-tracker-interfaces.vala

librygel_tracker_la_VALAFLAGS = --pkg posix \
				--pkg gupnp-dlna-1.0 \
				$(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_tracker_la_LIBADD = $(RYGEL_COMMON_LDADD) $(LIBGUPNP_DLNA_LIBS)
librygel_tracker_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
