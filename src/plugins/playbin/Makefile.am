include ../../../common.am

plugin_LTLIBRARIES = librygel-playbin.la

AM_CFLAGS += -DG_LOG_DOMAIN='"Playbin"' \
	-I$(top_srcdir)/src/librygel-renderer-gst \
	$(LIBGSTREAMER_CFLAGS)

librygel_playbin_la_SOURCES = rygel-module.vala
librygel_playbin_la_VALAFLAGS = \
	--pkg rygel-renderer-gst-2.0 \
	--vapidir $(top_srcdir)/src/librygel-renderer-gst \
	$(RYGEL_COMMON_RENDERER_PLUGIN_VALAFLAGS)
librygel_playbin_la_LIBADD = \
	$(top_builddir)/src/librygel-renderer-gst/librygel-renderer-gst-2.0.la \
	$(RYGEL_COMMON_RENDERER_LIBS)
librygel_playbin_la_LDFLAGS = $(RYGEL_PLUGIN_LINKER_FLAGS)
