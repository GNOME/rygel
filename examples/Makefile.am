include ../common.am

AM_CFLAGS += \
	-I$(top_builddir)/src/plugins/playbin \
	-I$(top_builddir)/src/rygel

noinst_PROGRAMS = standalone-renderer
standalone_renderer_SOURCES = standalone-renderer.c
standalone_renderer_LDADD = \
	$(top_builddir)/src/plugins/playbin/librygel-renderer-1.0.la \
	$(RYGEL_COMMON_LIBS)
