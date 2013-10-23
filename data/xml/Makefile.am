xml_in_files = MediaServer3.xml.in \
               MediaRenderer2.xml.in \
               ContentDirectory.xml.in \
               ContentDirectory-NoTrack.xml.in \
               ConnectionManager.xml.in \
               AVTransport2.xml.in \
               RenderingControl2.xml.in \
               BasicManagement2.xml.in \
               X_MS_MediaReceiverRegistrar1.xml.in

xml_DATA = $(xml_in_files:.xml.in=.xml)

# Strip newlines and leading spaces from XML files as not all devices like them
%.xml: $(srcdir)/%.xml.in
	@cat < $< | sed -re "s,^ +,,g" | tr -d "\n" > $@

xmldir = $(datadir)/rygel/xml

EXTRA_DIST = $(xml_in_files) MediaServer3.xml.in.in MediaRenderer2.xml.in.in
CLEANFILES = $(xml_DATA)

MAINTAINERCLEANFILES = Makefile.in MediaServer3.xml.in MediaRenderer2.xml.in
