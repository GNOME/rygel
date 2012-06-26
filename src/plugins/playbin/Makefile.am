include ../../../common.am

plugin_LTLIBRARIES = librygel-playbin.la

librygel_playbin_la_SOURCES = rygel-module.vala \
                              $(top_builddir)/src/librygel-renderer/rygel-renderer-1.0.vapi

librygel_playbin_la_CFLAGS = $(AM_CFLAGS) \
                             -I$(top_srcdir)/src/librygel-renderer \
                             -DG_LOG_DOMAIN='"Playbin"'

librygel_playbin_la_VALAFLAGS = $(RYGEL_COMMON_PLUGIN_VALAFLAGS)
librygel_playbin_la_LIBADD = $(RYGEL_COMMON_LIBS) \
                             $(top_builddir)/src/librygel-renderer/librygel-renderer-1.0.la

librygel_playbin_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
