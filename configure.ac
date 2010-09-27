AC_PREREQ(2.53)
AC_INIT([rygel],
	m4_esyscmd([GNOME_TAG_PATTERN=RYGEL build-aux/git-version-gen .tarball-version]),
	[http://bugzilla.gnome.org/enter_bug.cgi?product=Rygel])
AC_CONFIG_AUX_DIR([build-aux])

# require automake-1.11 for vala support
AM_INIT_AUTOMAKE([1.11])
AC_CONFIG_SRCDIR([src/rygel/rygel-root-device.vala])
AM_CONFIG_HEADER([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_MAINTAINER_MODE

# Disable generation of static libraries
AC_DISABLE_STATIC

AC_ISC_POSIX
AC_PROG_CC
AC_STDC_HEADERS
AC_PROG_LIBTOOL
AC_FUNC_MMAP

VALA_REQUIRED=0.9.5
GUPNP_REQUIRED=0.13.4
GUPNP_AV_REQUIRED=0.5.9
GUPNP_DLNA_REQUIRED=0.3.0
GUPNP_VALA_REQUIRED=0.6.11
DBUS_GLIB_REQUIRED=0.74
GSTREAMER_REQUIRED=0.10.23
GSTREAMER_TAG_REQUIRED=0.10.28
GSTREAMER_APP_REQUIRED=0.10.28
GIO_REQUIRED=2.16
GEE_REQUIRED=0.5.2
UUID_REQUIRED=1.41.3
LIBSOUP_REQUIRED=2.26.0
LIBSQLITE3_REQUIRED=3.5

PKG_CHECK_MODULES(LIBGUPNP, gupnp-1.0 >= $GUPNP_REQUIRED)
PKG_CHECK_MODULES(LIBGUPNP_AV, gupnp-av-1.0 >= $GUPNP_AV_REQUIRED)
PKG_CHECK_MODULES(LIBGUPNP_DLNA, gupnp-dlna-1.0 >= $GUPNP_DLNA_REQUIRED)
PKG_CHECK_MODULES(LIBDBUS_GLIB, dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
PKG_CHECK_MODULES(LIBGSTREAMER, gstreamer-0.10 >= $GSTREAMER_REQUIRED)
PKG_CHECK_MODULES(LIBGIO, gio-2.0 >= $GIO_REQUIRED)
PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
PKG_CHECK_MODULES(UUID, uuid >= $UUID_REQUIRED)
PKG_CHECK_MODULES(LIBSOUP, libsoup-2.4 >= $LIBSOUP_REQUIRED)

# glib-genmarshal
GLIB_GENMARSHAL=`pkg-config --variable=glib_genmarshal glib-2.0`
AC_SUBST(GLIB_GENMARSHAL)

AC_ARG_ENABLE(vala,
	[  --enable-vala          enable checks for vala],,
        enable_vala=no)
AC_ARG_ENABLE(sql-debugging,
              [  --enable-sql-debugging         enable SQL statement debugging],,
                 enable_sql_debugging=no)

if test x$enable_sql_debugging = xyes ; then
    VALAFLAGS="$VALAFLAGS -D RYGEL_DEBUG_SQL"
fi

# Enable check for Vala even if not asked to do so if stamp files are absent.
if test ! -e src/rygel/rygel_vala.stamp -o \
        ! -e src/rygel/librygel_configuration_a_vala.stamp -o \
        ! -e src/ui/rygel_preferences_vala.stamp -o \
        ! -e src/plugins/playbin/librygel_playbin_la_vala.stamp -o \
        ! -e src/plugins/tracker/librygel_media_tracker_la_vala.stamp -o \
        ! -e src/plugins/test/librygel_test_la_vala.stamp -o \
        ! -e src/plugins/media-export/librygel_media_export_la_vala.stamp -o \
        ! -e src/plugins/mediathek/librygel_mediathek_la_vala.stamp -o \
        ! -e src/plugins/gst-launch/librygel_gst_launch_la_vala.stamp -o \
        ! -e src/plugins/mpris/librygel_mpris_la_vala.stamp -o \
        ! -e src/plugins/external/librygel_external_la_vala.stamp ; then
    enable_vala=yes
fi

# Vala
if test x$enable_vala = xyes ; then
    # check for vala
    AM_PROG_VALAC([$VALA_REQUIRED])

    if test "x$VALAC" = "x"; then
        AC_MSG_ERROR([Cannot find the "valac" compiler in your PATH])
    fi

    PKG_CHECK_MODULES(GUPNP_VALA, gupnp-vala-1.0 >= $GUPNP_VALA_REQUIRED)

    VALA_CHECK_PACKAGES([gupnp-1.0
                         gupnp-av-1.0
                         gupnp-dlna-1.0
                         dbus-glib-1
                         gstreamer-0.10
                         gstreamer-discoverer-gupnp-dlna-0.10
                         gio-2.0
                         gee-1.0
                         posix])
else
    VAPIDIR=`echo ${datadir}/vala/vapi`
fi

AC_SUBST(VAPIDIR)

# Maemo support
AC_ARG_ENABLE(maemo,
	[  --enable-maemo          enable maemo support],,
        enable_maemo=no)

# Debugging
AC_ARG_ENABLE(debug,
	[  --enable-debug          enable debugging],,
        enable_debug=no)
if test "x$enable_debug" = "xyes"; then
        CFLAGS="$CFLAGS -O0 -g"
fi

# Strict compiler
AC_ARG_ENABLE(strict-cc,
	[  --enable-strict-cc          enable strict C compiler],,
        enable_strict_cc=no)
if test "x$enable_strict_cc" = "xyes"; then
        CFLAGS="$CFLAGS -Wall -Werror"
else
        CFLAGS="$CFLAGS -w"
fi

# Run uninstalled
AC_ARG_ENABLE(uninstalled,
	[  --enable-uninstalled          run uninstalled],,
        enable_uninstalled=no)
if test "x$enable_uninstalled" = "xyes"; then
        AC_MSG_WARN("You want to run the tools uninstalled only? Fine!")
fi

AC_MSG_CHECKING([which gtk+ version to compile against])
AC_ARG_WITH([gtk],
  [AS_HELP_STRING([--with-gtk=2.0|3.0],[which gtk+ version to compile against (default: 2.0)])],
  [case "$with_gtk" in
     2.0|3.0) ;;
     *) AC_MSG_ERROR([invalid gtk version specified]) ;;
   esac],
  [with_gtk=2.0])
AC_MSG_RESULT([$with_gtk])

case "$with_gtk" in
  2.0) GTK_VAPI_VERSION=2.0
       GTK_REQUIRED=2.20.0
       ;;
  3.0) GTK_VAPI_VERSION=3.0
       GTK_REQUIRED=2.90.3
       ;;
esac

# Check wether user wants to build UIs
AC_ARG_WITH( ui,
  AC_HELP_STRING([--without-ui],[Do not build UI applications]),
  try_ui=$withval, try_ui=yes )

HAVE_GTK=no
if test x$try_ui = xyes ; then
    dnl check for gtk
    PKG_CHECK_MODULES(GTK, gtk+-$GTK_VAPI_VERSION >= $GTK_REQUIRED ,
      [
        AC_SUBST(GTK_CFLAGS)
        AC_SUBST(GTK_LIBS)
        if test x$enable_vala = xyes ; then
                VALA_CHECK_PACKAGES([gtk+-$GTK_VAPI_VERSION], [HAVE_GTK=yes])
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
  with_gtk="n/a"
else
  BUILD_UI=yes
  AC_DEFINE(HAVE_GTK, , [Build UI applications])
fi

AC_SUBST(HAVE_GTK)
AC_SUBST(GTK_VAPI_VERSION)
AM_CONDITIONAL(BUILD_UI, test x$BUILD_UI = xyes)

# Build test plugin
AC_ARG_ENABLE(test-plugin,
	[  --enable-test-plugin          build test plugin],,
        enable_test_plugin=no)

# Build Tracker plugin
AC_ARG_ENABLE(tracker-plugin,
	[  --enable-tracker-plugin      build tracker plugin],,
        enable_tracker_plugin=yes)

# Build MediaExport plugin
AC_ARG_ENABLE(media-export-plugin,
	[  --enable-media-export-plugin          build MediaExport plugin],,
        enable_media_export_plugin=yes)

# Build External plugin
AC_ARG_ENABLE(external-plugin,
	[  --enable-external-plugin          build External plugin],,
        enable_external_plugin=yes)

# Build MPRIS2 plugin
AC_ARG_ENABLE(mpris-plugin,
	[  --enable-mpris-plugin             build MPRIS2 plugin],,
        enable_mpris_plugin=yes)

# Build GstRenderer plugin
AC_ARG_ENABLE(playbin-plugin,
	[  --enable-playbin_plugin          build Gstreamer Playbin plugin],,
        enable_playbin_plugin=yes)

# Build Mediathek plugin
AC_ARG_ENABLE(mediathek-plugin,
	[  --enable-mediathek-plugin          build Mediathek plugin],,
        enable_mediathek_plugin=no)

# Build GstLaunch plugin
AC_ARG_ENABLE(gst-launch-plugin,
	[  --enable-gst-launch-plugin          build Gstreamer launchline plugin],,
        enable_gst_launch_plugin=no)


AC_SUBST(abs_top_builddir)

AM_CONDITIONAL([UNINSTALLED], [test "x$enable_uninstalled" = "xyes"])
AM_CONDITIONAL([ENABLE_MAEMO], [test "x$enable_maemo" = "xyes"])
AM_CONDITIONAL([BUILD_TEST_PLUGIN], [test "x$enable_test_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_TRACKER_PLUGIN],
               [test "x$enable_tracker_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_MEDIATHEK_PLUGIN], [test "x$enable_mediathek_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_MEDIA_EXPORT_PLUGIN], [test "x$enable_media_export_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_EXTERNAL_PLUGIN], [test "x$enable_external_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_MPRIS_PLUGIN], [test "x$enable_mpris_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_PLAYBIN_PLUGIN], [test "x$enable_playbin_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_GST_LAUNCH_PLUGIN], [test "x$enable_gst_launch_plugin" = "xyes"])

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

# Gettext
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], 
  [Define the gettext package to be used])

AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

AC_SUBST(VALAFLAGS)

dnl Shave the output
AM_SILENT_RULES([yes])

dnl documenation
AC_PATH_PROG([XSLTPROC], [xsltproc])
AM_CONDITIONAL([HAVE_XSLTPROC], [test x"$XSLTPROC" != x])

AC_SUBST(VERSION)

AC_OUTPUT([
Makefile
src/Makefile
src/rygel/Makefile
src/ui/Makefile
src/plugins/Makefile
src/plugins/media-export/Makefile
src/plugins/external/Makefile
src/plugins/mpris/Makefile
src/plugins/gst-launch/Makefile
src/plugins/mediathek/Makefile
src/plugins/tracker/Makefile
src/plugins/playbin/Makefile
src/plugins/test/Makefile
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

echo "

                    ${PACKAGE} ${VERSION}
                    ============


        Prefix:                 ${prefix}
        Source code location:   ${srcdir}
        Compiler:               ${CC}
        CFLAGS:                 ${CFLAGS}
        uninstalled:            ${enable_uninstalled}
        maemo support:          ${enable_maemo}
        preferences ui:         ${BUILD_UI}
        GTK+ version:           ${with_gtk}
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
