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
	$(AM_V_GEN)$(XSLTPROC) -o $@ -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl >/dev/null 2>&1 $<
CLEANFILES = \
		$(dist_man1_MANS) $(dist_man5_MANS)

%.html: man/%.xml
	$(AM_V_GEN)$(XSLTPROC) -o $@ -nonet http://docbook.sourceforge.net/release/xsl/current/xhtml-1_1/docbook.xsl >/dev/null 2>&1 $<

endif
