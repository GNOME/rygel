SUBDIRS = librygel-core librygel-renderer librygel-server

if HAVE_GSTREAMER
SUBDIRS += librygel-renderer-gst
endif

SUBDIRS += rygel media-engines plugins

if BUILD_UI
SUBDIRS += ui
endif

MAINTAINERCLEANFILES = Makefile.in

vala-clean:
	rm -f `find . -name "*.stamp"`
