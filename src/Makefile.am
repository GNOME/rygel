SUBDIRS = librygel-core librygel-renderer librygel-server librygel-renderer-gst

SUBDIRS += rygel media-engines plugins

if BUILD_UI
SUBDIRS += ui
endif

MAINTAINERCLEANFILES = Makefile.in

vala-clean:
	rm -f `find . -name "*.stamp"`
