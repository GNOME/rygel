AC_PREREQ([2.64])
AC_INIT([Rygel],
	[m4_esyscmd(GNOME_TAG_PATTERN=RYGEL build-aux/git-version-gen .tarball-version)],
	[http://bugzilla.gnome.org/enter_bug.cgi?product=Rygel],
	[rygel],
	[http://live.gnome.org/Rygel])
AC_CONFIG_AUX_DIR([build-aux])

AC_CONFIG_SRCDIR([src/rygel/rygel-root-device.vala])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

AC_SEARCH_LIBS([strerror],[cposix])
AC_PROG_CC
AC_HEADER_STDC
AC_FUNC_MMAP

AC_SUBST(abs_top_builddir)
AC_SUBST(VERSION)

dnl Initialize automake
AM_INIT_AUTOMAKE([1.11.1])
AM_MAINTAINER_MODE([enable])

dnl Initialize libtool
dnl Disable generation of static libraries
LT_PREREQ([2.2.6])
LT_INIT([dlopen disable-static])

dnl Required versions of library packages
VALA_REQUIRED=0.11.6
GSSDP_MAX_VERSION=0.12.9999
GSSDP_REQUIRED=0.11.0
GUPNP_MAX_VERSION=0.18.9999
GUPNP_REQUIRED=0.17.0
GUPNP_AV_MAX_VERSION=0.10.9999
GUPNP_AV_REQUIRED=0.9.0
GUPNP_DLNA_MAX_VERSION=0.6.9999
GUPNP_DLNA_REQUIRED=0.5.0
GUPNP_VALA_REQUIRED=0.9.0
GSTREAMER_REQUIRED=0.10.23
GSTPBU_REQUIRED=0.10.30
GIO_REQUIRED=2.26
GEE_MAX_VERSION=0.6.9999
GEE_REQUIRED=0.5.2
UUID_REQUIRED=1.41.3
LIBSOUP_MAX_VERSION=2.36.9999
LIBSOUP_REQUIRED=2.34.0
GTK_REQUIRED=2.90.3

dnl Additional requirements for media-export plugin
GSTREAMER_TAG_REQUIRED=0.10.28
GSTREAMER_APP_REQUIRED=0.10.28
LIBSQLITE3_REQUIRED=3.5

PKG_CHECK_MODULES(LIBGSSDP, gssdp-1.0 >= $GSSDP_REQUIRED
                            gssdp-1.0 <= $GSSDP_MAX_VERSION)
PKG_CHECK_MODULES(LIBGUPNP, gupnp-1.0 >= $GUPNP_REQUIRED
                            gupnp-1.0 <= $GUPNP_MAX_VERSION)
PKG_CHECK_MODULES(LIBGUPNP_AV, gupnp-av-1.0 >= $GUPNP_AV_REQUIRED
                               gupnp-av-1.0 <= $GUPNP_AV_MAX_VERSION)
PKG_CHECK_MODULES(LIBGUPNP_DLNA, gupnp-dlna-1.0 >= $GUPNP_DLNA_REQUIRED
                                 gupnp-dlna-1.0 <= $GUPNP_DLNA_MAX_VERSION)
PKG_CHECK_MODULES(LIBGSTREAMER, gstreamer-0.10 >= $GSTREAMER_REQUIRED)
PKG_CHECK_MODULES(GSTREAMER_BASE, gstreamer-base-0.10 >= $GSTREAMER_REQUIRED)
PKG_CHECK_MODULES(GST_PBU, gstreamer-pbutils-0.10 >= $GSTPBU_REQUIRED)
PKG_CHECK_MODULES(LIBGIO, gio-2.0 >= $GIO_REQUIRED)
PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
PKG_CHECK_MODULES(UUID, uuid >= $UUID_REQUIRED)
PKG_CHECK_MODULES(LIBSOUP, libsoup-2.4 >= $LIBSOUP_REQUIRED
                           libsoup-2.4 <= $LIBSOUP_MAX_VERSION)

dnl glib-genmarshal
GLIB_GENMARSHAL=`pkg-config --variable=glib_genmarshal glib-2.0`
AC_SUBST(GLIB_GENMARSHAL)

AC_ARG_ENABLE(sql-debugging,
    AS_HELP_STRING([--enable-sql-debugging],[enable SQL statement debugging]),,
        enable_sql_debugging=no)
AS_IF([test x$enable_sql_debugging = xyes],
      [RYGEL_ADD_VALAFLAGS([-D RYGEL_DEBUG_SQL])])

dnl Add plugins
RYGEL_ADD_PLUGIN([test],[Test],[no])
RYGEL_ADD_PLUGIN([tracker],[Tracker],[yes])
RYGEL_ADD_PLUGIN([external],[MediaServer2 DBus consumer],[yes])
RYGEL_ADD_PLUGIN([mpris],[MPRIS2 DBus consumer],[yes])
RYGEL_ADD_PLUGIN([playbin],[GStreamer playbin],[yes])
RYGEL_ADD_PLUGIN([mediathek],[ZDF Mediathek],[no])
RYGEL_ADD_PLUGIN([media-export],[MediaExport],[yes])
RYGEL_ADD_PLUGIN([gst-launch],[GStreamer launchline],[no])

dnl Explicitly add stamp files for targets that are not plugins
RYGEL_ADD_STAMP([src/rygel/rygel_vala.stamp])
RYGEL_ADD_STAMP([src/ui/rygel_preferences_vala.stamp])

RYGEL_CHECK_VALA([$VALA_REQUIRED],
                 [gupnp-1.0
                  gupnp-av-1.0
                  gupnp-dlna-1.0
                  gstreamer-0.10
                  gstreamer-pbutils-0.10
                  gio-2.0
                  gee-1.0
                  posix])

dnl Debugging
AC_ARG_ENABLE(debug,
	AS_HELP_STRING([--enable-debug],[enable debugging]),,
        enable_debug=no)
if test "x$enable_debug" = "xyes"; then
        CFLAGS="$CFLAGS -O0 -g"
fi

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
        if test x$enable_vala = xyes ; then
                VALA_CHECK_PACKAGES([gtk+-3.0], [HAVE_GTK=yes])
        else
                HAVE_GTK=yes
        fi
      ],
      [
        HAVE_GTK=no
        AC_MSG_WARN([gtk $GTK_REQUIRED or greater not found.])
        AC_MSG_WARN([UI applications will not be built.])
      ])
else
    AC_MSG_NOTICE([UI applications disabled.])
fi

if test x$HAVE_GTK = xno; then
  BUILD_UI=no
else
  BUILD_UI=yes
  AC_DEFINE(HAVE_GTK, , [Build UI applications])
fi

AC_SUBST(HAVE_GTK)
AM_CONDITIONAL(BUILD_UI, test x$BUILD_UI = xyes)

dnl Check additional requirements for MediaExport plugins
if test "x$enable_media_export_plugin" = "xyes";
then
    PKG_CHECK_MODULES(LIBSQLITE3, sqlite3 >= $LIBSQLITE3_REQUIRED)
    PKG_CHECK_MODULES(GSTREAMER_TAG, gstreamer-tag-0.10 >= $GSTREAMER_TAG_REQUIRED);
    PKG_CHECK_MODULES(GSTREAMER_APP, gstreamer-app-0.10 >= $GSTREAMER_APP_REQUIRED);
    if test x$enable_vala = xyes ; then
        VALA_CHECK_PACKAGES([sqlite3
                             gstreamer-tag-0.10
                             gstreamer-app-0.10])
    fi
fi

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


AC_CONFIG_FILES([
Makefile
src/Makefile
src/rygel/Makefile
src/ui/Makefile
src/plugins/Makefile
data/Makefile
data/xml/Makefile
data/icons/Makefile
data/icons/32x32/Makefile
data/icons/48x48/Makefile
data/icons/120x120/Makefile
data/icons/scalable/Makefile
data/rygel.desktop.in
data/rygel-preferences.desktop.in
doc/Makefile
po/Makefile.in
rygel-1.0.pc
tests/Makefile
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
        preferences ui:         ${BUILD_UI}
        SQL debugging:          ${enable_sql_debugging}
    Plugins:
        test:                   ${enable_test_plugin}
        tracker:                ${enable_tracker_plugin}
        mediathek:              ${enable_mediathek_plugin}
        media-export            ${enable_media_export_plugin}
        external:               ${enable_external_plugin}
        MPRIS2:                 ${enable_mpris_plugin}
        gst-launch:             ${enable_gst_launch_plugin}
        playbin:                ${enable_playbin_plugin}
"
