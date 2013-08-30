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
dnl Not all of these are actually used, depending on the configure options.
GLIB_REQUIRED=2.31.13
LIBXML_REQUIRED=2.7
VALA_REQUIRED=0.20.0
VALADOC_REQUIRED=0.2
GSSDP_REQUIRED=0.13.0
GUPNP_REQUIRED=0.19.0
GUPNP_AV_REQUIRED=0.11.4
GUPNP_DLNA_REQUIRED=0.9.4
GSTREAMER_REQUIRED=1.0
GSTPBU_REQUIRED=1.0
GIO_REQUIRED=2.26
GEE_REQUIRED=0.8.0
UUID_REQUIRED=1.41.3
LIBSOUP_REQUIRED=2.34.0
GTK_REQUIRED=3.0

dnl Additional requirements for media-export plugin
GSTREAMER_TAG_REQUIRED=1.0
GSTREAMER_APP_REQUIRED=1.0
LIBSQLITE3_REQUIRED=3.5

dnl Additional requirements for tracker plugin
TRACKER_SPARQL_REQUIRED_MIN=0.14.0

VALAFLAGS="--target-glib=2.32 $VALAFLAGS"

RYGEL_BASE_MODULES="gupnp-1.0 >= $GUPNP_REQUIRED gee-0.8 >= $GEE_REQUIRED"
PKG_CHECK_MODULES([LIBRYGEL_CORE_DEPS], [$RYGEL_BASE_MODULES uuid >= $UUID_REQUIRED gssdp-1.0 >= $GSSDP_REQUIRED gio-2.0 >= $GIO_REQUIRED gmodule-2.0 libxml-2.0 >= $LIBXML_REQUIRED])
RYGEL_BASE_MODULES_VALAFLAGS='--pkg gupnp-1.0 --pkg gee-0.8'
LIBRYGEL_CORE_DEPS_VALAFLAGS="$RYGEL_BASE_MODULES_VALAFLAGS --pkg gssdp-1.0 --pkg gio-2.0 --pkg gmodule-2.0"
AC_SUBST([LIBRYGEL_CORE_DEPS_VALAFLAGS])

RYGEL_COMMON_MODULES="$RYGEL_BASE_MODULES gupnp-av-1.0 >= $GUPNP_AV_REQUIRED"
PKG_CHECK_MODULES([LIBRYGEL_SERVER_DEPS], [$RYGEL_COMMON_MODULES uuid >= $UUID_REQUIRED gssdp-1.0 >= $GSSDP_REQUIRED gio-2.0 >= $GIO_REQUIRED gmodule-2.0 libxml-2.0 >= $LIBXML_REQUIRED libsoup-2.4 >= $LIBSOUP_REQUIRED])
RYGEL_COMMON_MODULES_VALAFLAGS="$RYGEL_BASE_MODULES_VALAFLAGS --pkg gupnp-av-1.0"
LIBRYGEL_SERVER_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS --pkg gssdp-1.0 --pkg gio-2.0 --pkg libsoup-2.4 --pkg gmodule-2.0"
AC_SUBST([LIBRYGEL_SERVER_DEPS_VALAFLAGS])

PKG_CHECK_MODULES([LIBRYGEL_RENDERER_DEPS], [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED libsoup-2.4 >= $LIBSOUP_REQUIRED])
LIBRYGEL_RENDERER_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS --pkg gio-2.0 --pkg libsoup-2.4"
AC_SUBST([LIBRYGEL_RENDERER_DEPS_VALAFLAGS])

PKG_CHECK_MODULES([RYGEL_DEPS], [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED gssdp-1.0 >= $GSSDP_REQUIRED])

# Not all tests use all of these dependencies,
# but having one set of dependencies keeps things simple.
PKG_CHECK_MODULES([TEST_DEPS], [$RYGEL_COMMON_MODULES uuid >= $UUID_REQUIRED gio-2.0 >= $GIO_REQUIRED gssdp-1.0 >= $GSSDP_REQUIRED libsoup-2.4 >= $LIBSOUP_REQUIRED libxml-2.0 >= $LIBXML_REQUIRED])
TEST_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS --pkg gio-2.0 --pkg gssdp-1.0 --pkg libsoup-2.4 --pkg libxml-2.0 --pkg gmodule-2.0"
AC_SUBST([TEST_DEPS_VALAFLAGS])

PKG_CHECK_MODULES([EXAMPLE_DEPS], [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED gssdp-1.0 >= $GSSDP_REQUIRED])



dnl Media engine to use
BUILT_ENGINES="librygel-media-engine-simple"

dnl Disabling the gstreamer media_engine also disables
dnl anything else that uses gstreamer.
AC_ARG_WITH([media_engine],
            AS_HELP_STRING(
                [--with-media-engine=@<:@gstreamer|simple@:>@],
                [Media Engine to use]),
            [with_media_engine="$withval"],
            [with_media_engine="gstreamer"])

AS_IF([test "x$with_media_engine" = "xgstreamer"],
      [
        enable_gstreamer="yes"
        BUILT_ENGINES="$BUILT_ENGINES;librygel-media-engine-gst"

        PKG_CHECK_MODULES([RYGEL_MEDIA_ENGINE_GSTREAMER_DEPS],
                          [$RYGEL_COMMON_MODULES
                           gstreamer-pbutils-1.0 >= $GSTPBU_REQUIRED
                           gstreamer-app-1.0 >= $GSTREAMER_APP_REQUIRED
                           gupnp-dlna-2.0 >= $GUPNP_DLNA_REQUIRED
                           gio-2.0 >= $GIO_REQUIRED])
        RYGEL_MEDIA_ENGINE_GSTREAMER_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS --pkg gstreamer-base-1.0 --pkg gstreamer-pbutils-1.0 --pkg gupnp-dlna-2.0"
        AC_SUBST([RYGEL_MEDIA_ENGINE_GSTREAMER_DEPS_VALAFLAGS])

        PKG_CHECK_MODULES([LIBRYGEL_RENDERER_GST_DEPS], [$RYGEL_COMMON_MODULES gstreamer-1.0 >= $GSTREAMER_REQUIRED gio-2.0 >= $GIO_REQUIRED])
        LIBRYGEL_RENDERER_GST_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS --pkg gstreamer-1.0"
        AC_SUBST([LIBRYGEL_RENDERER_GST_DEPS_VALAFLAGS])
      ],
      [enable_gstreamer="no"])
AM_CONDITIONAL([HAVE_GSTREAMER],[test "x$enable_gstreamer" = "xyes"])
AC_SUBST([BUILT_ENGINES])

dnl Add plugins
RYGEL_ADD_PLUGIN([external],[MediaServer2 DBus consumer],[yes])
AS_IF([test "x$enable_external_plugin" = "xyes"],
  [
    PKG_CHECK_MODULES([RYGEL_PLUGIN_EXTERNAL_DEPS], [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED])
  ])

RYGEL_ADD_PLUGIN([mpris],[MPRIS2 DBus consumer],[yes])
AS_IF([test "x$enable_mpris_plugin" = "xyes"],
  [
    PKG_CHECK_MODULES([RYGEL_PLUGIN_MPRIS_DEPS], [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED])
  ])

RYGEL_ADD_PLUGIN([mediathek],[ZDF Mediathek],[no])
AS_IF([test "x$enable_mediathek_plugin" = "xyes"],
  [
    PKG_CHECK_MODULES([RYGEL_PLUGIN_MEDIATHEK_DEPS],
                      [$RYGEL_COMMON_MODULES
                       gio-2.0 >= $GIO_REQUIRED
                       libsoup-2.4 >= $LIBSOUP_REQUIRED
                       libxml-2.0 >= $LIBXML_REQUIRED])
  ])

AS_IF([test "x$with_media_engine" = "xgstreamer"],
      [
        RYGEL_ADD_PLUGIN([playbin],[GStreamer playbin],[yes])
        AS_IF([test "x$enable_playbin_plugin" = "xyes"],
          [
            PKG_CHECK_MODULES([RYGEL_PLUGIN_PLAYBIN_DEPS], [$RYGEL_COMMON_MODULES gstreamer-1.0 >= $GSTREAMER_TAG_REQUIRED])
          ])

        RYGEL_ADD_PLUGIN([media-export],[MediaExport],[yes])
        AS_IF([test "x$enable_media_export_plugin" = "xyes"],
          [
            PKG_CHECK_MODULES([RYGEL_PLUGIN_MEDIA_EXPORT_DEPS],
                              [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED
                               gupnp-dlna-2.0 >= $GUPNP_DLNA_REQUIRED
                               gupnp-dlna-gst-2.0 >= $GUPNP_DLNA_REQUIRED
                               gstreamer-app-1.0 >= $GSTREAMER_APP_REQUIRED
                               gstreamer-tag-1.0 >= $GSTREAMER_TAG_REQUIRED
                               gstreamer-pbutils-1.0 >= $GSTPBU_REQUIRED
                               libsoup-2.4 >= $LIBSOUP_REQUIRED
                               sqlite3 >= $LIBSQLITE3_REQUIRED
                               uuid])
            RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS --pkg gupnp-dlna-2.0 --pkg gupnp-dlna-gst-2.0 --pkg gstreamer-tag-1.0 --pkg gstreamer-app-1.0 --pkg gstreamer-pbutils-1.0 --pkg sqlite3"
            AC_SUBST([RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_VALAFLAGS])
          ])

        RYGEL_ADD_PLUGIN([gst-launch],[GStreamer launchline],[no])
        AS_IF([test "x$enable_gst_launch_plugin" = "xyes"],
          [
            PKG_CHECK_MODULES([RYGEL_PLUGIN_GST_LAUNCH_DEPS], [$RYGEL_COMMON_MODULES])
            RYGEL_PLUGIN_GST_LAUNCH_DEPS_VALAFLAGS="$RYGEL_COMMON_MODULES_VALAFLAGS"
            AC_SUBST([RYGEL_PLUGIN_GST_LAUNCH_DEPS_VALAFLAGS])
          ])

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

AS_IF([test "x$with_media_engine" = "xgstreamer"],
      [
        RYGEL_CHECK_PACKAGES([gupnp-dlna-2.0 gstreamer-1.0
                              gstreamer-pbutils-1.0])
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
    PKG_CHECK_MODULES([RYGEL_UI_DEPS], [$RYGEL_BASE_MODULES gtk+-3.0 >= $GTK_REQUIRED gssdp-1.0 >= $GSSDP_REQUIRED gee-0.8 >= $GEE_REQUIRED],
      [
        RYGEL_CHECK_PACKAGES([gtk+-3.0], [HAVE_GTK=yes])
        RYGEL_UI_DEPS_VALAFLAGS="$RYGEL_BASE_MODULES_VALAFLAGS --pkg gtk+-3.0 --pkg gssdp-1.0 --pkg gee-0.8"
        AC_SUBST([RYGEL_UI_DEPS_VALAFLAGS])

        PKG_CHECK_MODULES([EXAMPLE_UI_DEPS],
                          [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED
                           gssdp-1.0 >= $GSSDP_REQUIRED
                           gstreamer-video-1.0 >= $GSTREAMER_REQUIRED
                           gtk+-3.0 >= $GTK_REQUIRED])
      ],
      [
        AC_MSG_WARN([UI dependencies not found.])
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
    RYGEL_CHECK_PACKAGES([sqlite3 gstreamer-tag-1.0 gstreamer-app-1.0])
    AC_CHECK_HEADER([unistr.h],
                    AC_CHECK_LIB([unistring],
                                 [u8_strcoll],
                                 [have_unistring=yes],[have_unistring=no]))
    if test "x$have_unistring" = "xyes"; then
        AC_DEFINE([HAVE_UNISTRING],[1],[Use libunistring for collation])
        RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_LIBS="$RYGEL_PLUGIN_MEDIA_EXPORT_DEPS_LIBS -lunistring"
    fi
fi


RYGEL_ADD_PLUGIN([tracker],[Tracker],[yes])
AS_IF([test "x$enable_tracker_plugin" = "xyes"],
  [
    PKG_CHECK_MODULES([RYGEL_PLUGIN_TRACKER_DEPS], [$RYGEL_COMMON_MODULES gio-2.0 >= $GIO_REQUIRED])

    tracker_api_version="0.14"
    PKG_CHECK_MODULES(TRACKER_SPARQL,
                      tracker-sparql-0.14 >= $TRACKER_SPARQL_REQUIRED_MIN,
                      [tracker_api_version="0.14"],
                      [tracker_api_version=""])
    AS_IF([test "x$[]tracker_api_version" = "x"],
          [
            PKG_CHECK_MODULES(TRACKER_SPARQL,
                              tracker-sparql-0.15 >=  $TRACKER_SPARQL_REQUIRED_MIN,
                              [tracker_api_version="0.15"],
                              [tracker_api_version=""])
          ])
    AS_IF([test "x$[]tracker_api_version" = "x"],
          [
            PKG_CHECK_MODULES(TRACKER_SPARQL,
                              tracker-sparql-0.16 >=  $TRACKER_SPARQL_REQUIRED_MIN,
                              [tracker_api_version="0.16"],
                              [])
          ])
    AS_IF([test "x$enable_vala" = "xyes"],
          [VALA_CHECK_PACKAGES([tracker-sparql-$tracker_api_version])])

    RYGEL_PLUGIN_TRACKER_DEPS_VALAFLAGS="--pkg tracker-sparql-$tracker_api_version"
    AC_SUBST([RYGEL_PLUGIN_TRACKER_DEPS_VALAFLAGS])
  ])

# This should be called only after all RYGEL_CHECK_VALA() and RYGEL_ADD_PLUGIN() calls:
RYGEL_CHECK_VALA([$VALA_REQUIRED],
                 [gupnp-1.0
                  gupnp-av-1.0
                  gio-2.0
                  gee-0.8
                  posix])

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

AC_SUBST([RYGEL_PLUGIN_LINKER_FLAGS],
         ["-module -avoid-version -Wl,-z,defs"])
AC_SUBST([RYGEL_PLUGIN_DIR],
         [${libdir}/rygel-2.0/plugins])
AC_SUBST([RYGEL_MEDIA_ENGINE_DIR],
         [${libdir}/rygel-2.0/engines])

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
src/media-engines/gstreamer/media-engine-gst.plugin
src/media-engines/simple/Makefile
src/media-engines/simple/media-engine-simple.plugin
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
examples/renderer-plugins/vala/example-renderer-vala.plugin
examples/renderer-plugins/C/Makefile
examples/renderer-plugins/C/example-renderer-c.plugin
examples/server-plugins/Makefile
examples/server-plugins/vala/Makefile
examples/server-plugins/vala/example-server-vala.plugin
examples/server-plugins/C/Makefile
examples/server-plugins/C/example-server-c.plugin
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
        tracker:                ${enable_tracker_plugin}
            version:            ${tracker_api_version}
        mediathek:              ${enable_mediathek_plugin}
        media-export            ${enable_media_export_plugin}
        external:               ${enable_external_plugin}
        MPRIS2:                 ${enable_mpris_plugin}
        gst-launch:             ${enable_gst_launch_plugin}
        playbin:                ${enable_playbin_plugin}
"
