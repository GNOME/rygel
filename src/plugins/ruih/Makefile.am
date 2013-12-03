include $(top_srcdir)/common.am

plugin_LTLIBRARIES = librygel-ruih.la
plugin_DATA = ruih.plugin

librygel_ruih_la_SOURCES = rygel-ruih-module.vala rygel-ruih-plugin.vala
librygel_ruih_la_VALAFLAGS = \
        --pkg rygel-ruih-2.0 \
        --vapidir $(top_srcdir)/src/librygel-ruih \
        $(RYGEL_COMMON_LIBRYGEL_RUIH_VALAFLAGS) \
        $(RYGEL_COMMON_VALAFLAGS)
librygel_ruih_la_CFLAGS = \
        $(RYGEL_PLUGIN_RUIH_DEPS_CFLAGS) \
        $(RYGEL_COMMON_LIBRYGEL_RUIH_CFLAGS) \
        -DG_LOG_DOMAIN='"Ruih"'
librygel_ruih_la_LIBADD = \
        $(RYGEL_PLUGIN_RUIH_DEPS_LIBS) \
        $(RYGEL_COMMON_LIBRYGEL_RUIH_LIBS)
librygel_ruih_la_LDFLAGS = \
        $(RYGEL_PLUGIN_LINKER_FLAGS)

EXTRA_DIST = ruih.plugin.in
