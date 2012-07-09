if BUILD_UI
SUBDIRS = librygel-core librygel-renderer librygel-server rygel ui plugins
else
SUBDIRS = librygel-core librygel-renderer librygel-server rygel plugins
endif

MAINTAINERCLEANFILES = Makefile.in

vala-clean:
	rm -f `find . -name "*.stamp"`
