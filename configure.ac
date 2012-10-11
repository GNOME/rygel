AC_PREREQ([2.64])
AC_INIT([Rygel],
	[m4_esyscmd(GNOME_TAG_PATTERN=RYGEL build-aux/git-version-gen .tarball-version)],
	[http://bugzilla.gnome.org/enter_bug.cgi?product=Rygel],
	[rygel],
	[http://live.gnome.org/Rygel])
AC_CONFIG_AUX_DIR([build-aux])

AC_CONFIG_SRCDIR([src/librygel-core/rygel-root-device.vala])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

AC_SEARCH_LIBS([strerror],[cposix])
AC_PROG_CC
AC_HEADER_STDC
AC_FUNC_MMAP

AC_SUBST(abs_top_builddir)
AC_SUBST(VERSION)

dnl Initialize automake
AM_INIT_AUTOMAKE([1.11.1 tar-ustar no-dist-gzip dist-xz -Wno-portability])
AM_MAINTAINER_MODE([enable])

dnl Initialize libtool
dnl Disable generation of static libraries
LT_PREREQ([2.2.6])
LT_INIT([dlopen disable-static])

dnl Required versions of library packages
GLIB_REQUIRED=2.31.13
VALA_REQUIRED=0.16.1
VALADOC_REQUIRED=0.2
GSSDP_REQUIRED=0.13.0
GUPNP_REQUIRED=0.19.0
GUPNP_AV_REQUIRED=0.11.2
GUPNP_DLNA_REQUIRED=0.5.0
GSTREAMER_REQUIRED=0.10.36
GSTPBU_REQUIRED=0.10.35
GIO_REQUIRED=2.26
GEE_REQUIRED=0.5.2
UUID_REQUIRED=1.41.3
LIBSOUP_REQUIRED=2.34.0
GTK_REQUIRED=2.90.3

dnl Additional requirements for media-export plugin
GSTREAMER_TAG_REQUIRED=0.10.28
GSTREAMER_APP_REQUIRED=0.10.28
LIBSQLITE3_REQUIRED=3.5

dnl Additional requirements for tracker plugin
TRACKER_SPARQL_REQUIRED_MIN=0.14.0

PKG_CHECK_MODULES(LIBGLIB, glib-2.0 >= $GLIB_REQUIRED)
VALAFLAGS="--target-glib=2.32 $VALAFLAGS"

PKG_CHECK_MODULES(LIBGSSDP, gssdp-1.0 >= $GSSDP_REQUIRED)
PKG_CHECK_MODULES(LIBGUPNP, gupnp-1.0 >= $GUPNP_REQUIRED)
PKG_CHECK_MODULES(LIBGUPNP_AV, gupnp-av-1.0 >= $GUPNP_AV_REQUIRED)
PKG_CHECK_MODULES(LIBGIO, gio-2.0 >= $GIO_REQUIRED)
PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
PKG_CHECK_MODULES(UUID, uuid >= $UUID_REQUIRED)
PKG_CHECK_MODULES(LIBSOUP, libsoup-2.4 >= $LIBSOUP_REQUIRED)

dnl Media engine to use
BUILT_ENGINES="librygel-media-engine-simple"

AC_ARG_WITH([media_engine],
            AS_HELP_STRING(
                [--with-media-engine=@<:@gstreamer|none@:>@],
                [Media Engine to use]),
            [with_media_engine="$withval"],
            [with_media_engine="gstreamer"])

AS_IF([test "x$with_media_engine" = "xgstreamer"],
      [
        PKG_CHECK_MODULES(LIBGUPNP_DLNA, gupnp-dlna-1.0 >= $GUPNP_DLNA_REQUIRED)
        PKG_CHECK_MODULES(LIBGSTREAMER, gstreamer-0.10 >= $GSTREAMER_REQUIRED)
        PKG_CHECK_MODULES(GSTREAMER_BASE, gstreamer-base-0.10 >= $GSTREAMER_REQUIRED)
        PKG_CHECK_MODULES(GST_PBU, gstreamer-pbutils-0.10 >= $GSTPBU_REQUIRED)
        enable_gstreamer="yes"
        BUILT_ENGINES="$BUILT_ENGINES;librygel-media-engine-gst"
      ],
      [enable_gstreamer="no"])
AM_CONDITIONAL([HAVE_GSTREAMER],[test "x$enable_gstreamer" = "xyes"])
AC_SUBST([BUILT_ENGINES])

dnl Add plugins
RYGEL_ADD_PLUGIN([external],[MediaServer2 DBus consumer],[yes])
RYGEL_ADD_PLUGIN([mpris],[MPRIS2 DBus consumer],[yes])
RYGEL_ADD_PLUGIN([mediathek],[ZDF Mediathek],[no])
RYGEL_ADD_PLUGIN([tracker],[Tracker],[yes])

AS_IF([test "x$with_media_engine" = "xgstreamer"],
      [
        RYGEL_ADD_PLUGIN([playbin],[GStreamer playbin],[yes])
        RYGEL_ADD_PLUGIN([media-export],[MediaExport],[yes])
        RYGEL_ADD_PLUGIN([gst-launch],[GStreamer launchline],[no])
        RYGEL_ADD_STAMP([src/media-engines/gstreamer/librygel_media_engine_gst_la_vala.stamp])
        RYGEL_ADD_STAMP([src/librygel-renderer-gst/librygel_renderer_gst_2_0_la_vala.stamp])
      ],
      [
        RYGEL_DISABLE_PLUGIN([playbin])
        RYGEL_DISABLE_PLUGIN([media-export])
        RYGEL_DISABLE_PLUGIN([gst-launch])
      ])
 
dnl Example plugins:     
AC_ARG_ENABLE([example-plugins],
              AS_HELP_STRING([--enable-example-plugins],[enable example plugins]),,
              enable_example_plugins=no)
AM_CONDITIONAL([BUILD_EXAMPLE_PLUGINS], [test "x$[]enable_example_plugins" = "xyes"])

dnl Explicitly add stamp files for targets that are not plugins
RYGEL_ADD_STAMP([src/librygel-core/librygel_core_2_0_la_vala.stamp])
RYGEL_ADD_STAMP([src/librygel-server/librygel_server_2_0_la_vala.stamp])
RYGEL_ADD_STAMP([src/librygel-renderer/librygel_renderer_2_0_la_vala.stamp])
RYGEL_ADD_STAMP([src/rygel/rygel_vala.stamp])
RYGEL_ADD_STAMP([src/ui/rygel_preferences_vala.stamp])
RYGEL_ADD_STAMP([src/media-engines/simple/librygel_media_engine_simple_la_vala.stamp])

RYGEL_CHECK_VALA([$VALA_REQUIRED],
                 [gupnp-1.0
                  gupnp-av-1.0
                  gio-2.0
                  gee-1.0
                  posix])

AS_IF([test "x$with_media_engine" = "xgstreamer"],
      [
        RYGEL_CHECK_PACKAGES([gupnp-dlna-1.0 gstreamer-0.10 gstreamer-pbutils-0.10])
      ])

dnl Debugging
AC_ARG_ENABLE(debug,
	AS_HELP_STRING([--enable-debug],[enable debugging]),,
        enable_debug=no)
if test "x$enable_debug" = "xyes"; then
        CFLAGS="$CFLAGS -O0 -g"
        RYGEL_DEBUG_VALAFLAGS="-g"
fi

AC_SUBST(RYGEL_DEBUG_VALAFLAGS)

dnl Strict compiler
AC_ARG_ENABLE(strict-cc,
	AS_HELP_STRING([--enable-strict-cc],[enable strict C compiler]),,
        enable_strict_cc=no)
if test "x$enable_strict_cc" = "xyes"; then
        CFLAGS="$CFLAGS -Wall -Werror"
else
        CFLAGS="$CFLAGS -w"
fi

dnl Run uninstalled
AC_ARG_ENABLE(uninstalled,
    AS_HELP_STRING([--enable-uninstalled],[run uninstalled]),,
        enable_uninstalled=no)
if test "x$enable_uninstalled" = "xyes"; then
        AC_MSG_WARN("You want to run the tools uninstalled only? Fine!")
fi
AM_CONDITIONAL([UNINSTALLED], [test "x$enable_uninstalled" = "xyes"])

dnl Check wether user wants to build UIs
AC_ARG_WITH( ui,
  AS_HELP_STRING([--without-ui],[Do not build UI applications]),
  try_ui=$withval, try_ui=yes )

HAVE_GTK=no
if test x$try_ui = xyes ; then
    dnl check for gtk
    PKG_CHECK_MODULES(GTK, gtk+-3.0 >= $GTK_REQUIRED,
      [
        RYGEL_CHECK_PACKAGES([gtk+-3.0], [HAVE_GTK=yes])
      ],
      [
        AC_MSG_WARN([gtk $GTK_REQUIRED or greater not found.])
        AC_MSG_WARN([UI applications will not be built.])
      ])
else
    AC_MSG_NOTICE([UI applications disabled.])
fi

AM_CONDITIONAL(BUILD_UI, test "x$HAVE_GTK" = "xyes")

dnl Tests
AC_ARG_ENABLE([tests],
              AS_HELP_STRING([--enable-tests],[always build tests]),,
              enable_tests=no)
AM_CONDITIONAL([ALWAYS_TEST], [test "x$enable_tests" = "xyes"])

dnl Generate coverage data
AC_ARG_ENABLE([coverage],
  AS_HELP_STRING([--enable-coverage],
                 [Generate converage reports for unit tests]),
  [],
  [enable_coverage=no])
AM_CONDITIONAL([ENABLE_COVERAGE],[test "x$enable_coverage" != "xno"])
AS_IF([test "x$enable_coverage" != "xno"],
  [
    AC_PATH_PROG([LCOV], [lcov])
    AC_PATH_PROG([GENHTML], [genhtml])
    AC_SUBST([COVERAGE_LIBS],["-lgcov"])
    AC_SUBST([COVERAGE_CFLAGS],["-fprofile-arcs -ftest-coverage"])
    AC_SUBST(COVERAGE_VALAFLAGS,["-g"])
  ]
)

dnl Check additional requirements for MediaExport plugins
if test "x$enable_media_export_plugin" = "xyes";
then
    PKG_CHECK_MODULES(LIBSQLITE3, sqlite3 >= $LIBSQLITE3_REQUIRED)
    PKG_CHECK_MODULES(GSTREAMER_TAG, gstreamer-tag-0.10 >= $GSTREAMER_TAG_REQUIRED);
    PKG_CHECK_MODULES(GSTREAMER_APP, gstreamer-app-0.10 >= $GSTREAMER_APP_REQUIRED);
    RYGEL_CHECK_PACKAGES([sqlite3 gstreamer-tag-0.10 gstreamer-app-0.10])
    AC_CHECK_HEADER([unistr.h],
                    AC_CHECK_LIB([unistring],
                                 [u8_strcoll],
                                 [have_unistring=yes],[have_unistring=no]))
    if test "x$have_unistring" = "xyes"; then
        AC_DEFINE([HAVE_UNISTRING],[1],[Use libunistring for collation])
        COLLATION_CFLAGS=
        COLLATION_LIBS=-lunistring
        AC_SUBST([COLLATION_CFLAGS])
        AC_SUBST([COLLATION_LIBS])
    fi
fi

AS_IF([test "x$enable_tracker_plugin" = "xyes"],
  [
    PKG_CHECK_MODULES(TRACKER_SPARQL,
                      tracker-sparql-0.14 >= $TRACKER_SPARQL_REQUIRED_MIN)
    AS_IF([test "x$enable_vala" = "xyes"],
          [VALA_CHECK_PACKAGES([tracker-sparql-0.14])])
  ])

dnl Gettext
GETTEXT_PACKAGE=rygel
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], 
  [Define the gettext package to be used])

AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.40.0])

dnl Shave the output
AM_SILENT_RULES([yes])

dnl documenation
AC_PATH_PROG([XSLTPROC], [xsltproc])
AM_CONDITIONAL([HAVE_XSLTPROC], [test x"$XSLTPROC" != x])

dnl Use valadoc for API documentation:
dnl This is on by default when using autogen.sh 
dnl (so it is not on by default when building from a tarball with configure.)
AC_ARG_ENABLE(valadoc,
  AS_HELP_STRING([--enable-valadoc[=@<:@no/auto/yes@:>@]], [Enable valadoc support]),,
    [enable_valadoc=no])

found_valadoc=no
AS_IF([test "x$enable_valadoc" != "xno"], [
    AC_PATH_PROG(VALADOC, valadoc, :)
    AS_IF([test -x "$VALADOC"], [
      found_valadoc=yes
      AC_SUBST(VALADOC)
      PKG_CHECK_MODULES([GTKDOC],[gtk-doc >= 1.0])
    ], [
      AS_IF([test "x$enable_valadoc" == "xyes"], AC_MSG_ERROR([Unable to find valadoc]))
    ])
  ])

AM_CONDITIONAL(ENABLE_VALADOC, test x$found_valadoc = xyes)

AC_CONFIG_FILES([
Makefile
src/Makefile
src/librygel-core/Makefile
src/librygel-renderer/Makefile
src/librygel-renderer-gst/Makefile
src/librygel-server/Makefile
src/rygel/Makefile
src/ui/Makefile
src/media-engines/Makefile
src/media-engines/gstreamer/Makefile
src/media-engines/simple/Makefile
src/plugins/Makefile
data/Makefile
data/xml/Makefile
data/xml/MediaServer3.xml.in
data/xml/MediaRenderer2.xml.in
data/icons/Makefile
data/icons/32x32/Makefile
data/icons/48x48/Makefile
data/icons/120x120/Makefile
data/icons/128x128/Makefile
data/icons/scalable/Makefile
data/rygel.desktop.in
data/rygel-preferences.desktop.in
doc/Makefile
doc/reference/Makefile
doc/reference/librygel-core/Makefile
doc/reference/librygel-renderer/Makefile
doc/reference/librygel-server/Makefile
doc/reference/librygel-renderer-gst/Makefile
po/Makefile.in
rygel-core-2.0.pc
rygel-renderer-2.0.pc
rygel-server-2.0.pc
rygel-renderer-gst-2.0.pc
tests/Makefile
examples/Makefile
examples/renderer-plugins/Makefile
examples/renderer-plugins/vala/Makefile
examples/server-plugins/Makefile
examples/server-plugins/vala/Makefile
])
AC_OUTPUT

echo "

                    ${PACKAGE} ${VERSION}
                    ============


        Prefix:                 ${prefix}
        Source code location:   ${srcdir}
        Compiler:               ${CC}
        CFLAGS:                 ${CFLAGS}
        VALAFLAGS:              ${VALAFLAGS}
        uninstalled:            ${enable_uninstalled}
        preferences ui:         ${HAVE_GTK}
        Media Engine:           ${with_media_engine}
    Plugins:
        examples:               ${enable_example_plugins}
        test:                   ${enable_test_plugin}
        tracker:                ${enable_tracker_plugin}
        mediathek:              ${enable_mediathek_plugin}
        media-export            ${enable_media_export_plugin}
        external:               ${enable_external_plugin}
        MPRIS2:                 ${enable_mpris_plugin}
        gst-launch:             ${enable_gst_launch_plugin}
        playbin:                ${enable_playbin_plugin}
"
