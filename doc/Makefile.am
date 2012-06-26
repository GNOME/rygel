SUBDIRS = reference

dist_man1_MANS = \
		rygel.1

dist_man5_MANS = \
		rygel.conf.5

EXTRA_DIST = \
		man/rygel.xml \
		man/rygel.conf.xml \
		README.Mediathek

if HAVE_XSLTPROC
%.5 %.1: man/%.xml
	$(XSLTPROC) -o $@ -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $<
CLEANFILES = \
		$(dist_man1_MANS) $(dist_man5_MANS)
endif
