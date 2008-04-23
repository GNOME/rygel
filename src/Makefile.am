if UNINSTALLED
shareddir = $(abs_top_builddir)/data
else
shareddir = $(datadir)/gupnp-tools
endif

AM_CFLAGS = $(LIBGUPNP_CFLAGS) $(LIBGLADE_CFLAGS) -I$(top_srcdir) \
	    -DDATA_DIR='"$(shareddir)"' -I../common

bin_PROGRAMS = gupnp-network-light

gupnp_network_light_SOURCES = main.c \
			      gui.c \
			      upnp.c \
			      main.h \
			      gui.h \
			      upnp.h
gupnp_network_light_LDADD = $(LIBGLADE_LIBS) $(LIBGUPNP_LIBS) \
			    ../common/libicons.a
gupnp_network_light_LDFLAGS = -export-dynamic

MAINTAINERCLEANFILES = Makefile.in
