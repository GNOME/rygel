if BUILD_UI
SUBDIRS = librygel-core librygel-renderer rygel ui plugins
else
SUBDIRS = librygel-core librygel-renderer rygel plugins
endif

MAINTAINERCLEANFILES = Makefile.in

vala-clean:
	rm -f `find . -name "*.stamp"`
