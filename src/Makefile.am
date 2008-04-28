if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/gupnp-media-server
endif

AM_CFLAGS = $(LIBGUPNP_CFLAGS) $(LIBGUPNP_AV_CFLAGS) $(LIBGCONF_CFLAGS) \
	    -I$(top_srcdir) -DDATA_DIR='"$(shareddir)"'

bin_PROGRAMS = gupnp-media-server

gupnp_media_server_SOURCES = main.c \
			     gupnp-media-server.h \
			     gupnp-media-server.c \
			     gupnp-media-tracker.h \
			     gupnp-media-tracker.c
gupnp_media_server_LDADD = $(LIBGUPNP_LIBS) \
			   $(LIBGUPNP_AV_LIBS) \
			   $(LIBGCONF_LIBS)
gupnp_media_server_LDFLAGS = -export-dynamic

MAINTAINERCLEANFILES = Makefile.in
