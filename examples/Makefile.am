# Avoid using the example plugins dirs at all
# if they are not enabled, to avoid
# installing them.
if BUILD_EXAMPLE_PLUGINS
EXAMPLE_PLUGINS = renderer-plugins server-plugins
endif

SUBDIRS = $(EXAMPLE_PLUGINS)


include $(top_srcdir)/common.am


#TODO: Remove the src/rygel from here?
noinst_PROGRAMS = standalone-server
standalone_server_SOURCES = standalone-server.c
standalone_server_CFLAGS = \
	$(EXAMPLE_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_CFLAGS)
standalone_server_LDADD = \
	$(EXAMPLE_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_SERVER_LIBS)

if HAVE_GSTREAMER

noinst_PROGRAMS += standalone-renderer-gst
standalone_renderer_gst_SOURCES = standalone-renderer-gst.c
standalone_renderer_gst_CFLAGS = \
	$(EXAMPLE_DEPS_CFLAGS) \
	$(LIBRYGEL_RENDERER_GST_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_CFLAGS)
standalone_renderer_gst_LDADD = \
	$(EXAMPLE_DEPS_LIBS) \
	$(LIBRYGEL_RENDERER_GST_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_LIBS)

if BUILD_UI
noinst_PROGRAMS += fullscreen-renderer
fullscreen_renderer_SOURCES = fullscreen-renderer.c
fullscreen_renderer_CFLAGS = \
	$(EXAMPLE_UI_DEPS_CFLAGS) \
	$(LIBRYGEL_RENDERER_GST_DEPS_CFLAGS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_CFLAGS)
fullscreen_renderer_LDADD = \
	$(EXAMPLE_UI_DEPS_LIBS) \
	$(LIBRYGEL_RENDERER_GST_DEPS_LIBS) \
	$(RYGEL_COMMON_LIBRYGEL_RENDERER_GST_LIBS)
endif
endif

EXTRA_DIST = service/wrap-dbus \
service/sysv/rygel \
service/README.Ubuntu \
service/upstart/rygel.conf \
service/systemd/rygel.service
