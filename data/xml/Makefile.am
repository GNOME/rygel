xml_in_files = MediaServer2.xml.in \
	       MediaRenderer2.xml.in \
               ContentDirectory.xml.in \
               ConnectionManager.xml.in \
               AVTransport2.xml.in \
               RenderingControl2.xml.in \
               X_MS_MediaReceiverRegistrar1.xml.in

xml_DATA = $(xml_in_files:.xml.in=.xml)

# Strip newlines and leading spaces from XML files as not all devices like them
$(xml_DATA): $(xml_in_files) Makefile
	@cat < $(@:.xml=.xml.in) | sed -re "s,^ +,,g" | tr -d "\n" > $@

xmldir = $(datadir)/rygel/xml

EXTRA_DIST = $(xml_DATA) $(xml_in_files)

MAINTAINERCLEANFILES = Makefile.in
