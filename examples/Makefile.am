# Avoid using the example plugins dirs at all
# if they are not enabled, to avoid
# installing them.
if BUILD_EXAMPLE_PLUGINS
EXAMPLE_PLUGINS = renderer-plugins server-plugins
endif

SUBDIRS = $(EXAMPLE_PLUGINS)


include ../common.am

AM_CFLAGS += \
	-I$(top_builddir)/src/librygel-server \
	-I$(top_srcdir)/src/librygel-server \
	-I$(top_builddir)/src/rygel \
	-I$(top_srcdir)/src/rygel

noinst_PROGRAMS = standalone-server
standalone_server_SOURCES = standalone-server.c
standalone_server_LDADD = \
	$(top_builddir)/src/librygel-server/librygel-server-2.0.la \
	$(LIBGIO_LIBS) \
	$(RYGEL_COMMON_LIBS)

if HAVE_GSTREAMER
AM_CFLAGS += \
	-I$(top_builddir)/src/librygel-renderer-gst \
	-I$(top_srcdir)/src/librygel-renderer-gst \
	-I$(top_builddir)/src/librygel-renderer \
	-I$(top_srcdir)/src/librygel-renderer \
	$(LIBGSTREAMER_CFLAGS)

noinst_PROGRAMS += standalone-renderer
standalone_renderer_SOURCES = standalone-renderer.c
standalone_renderer_LDADD = \
	$(top_builddir)/src/librygel-renderer/librygel-renderer-2.0.la \
	$(top_builddir)/src/librygel-renderer-gst/librygel-renderer-gst-2.0.la \
	$(LIBGSTREAMER_LIBS) \
	$(RYGEL_COMMON_LIBS)
endif

EXTRA_DIST = service/wrap-dbus \
service/sysv/rygel \
service/README.Ubuntu \
service/upstart/rygel.conf \
service/systemd/rygel.service
