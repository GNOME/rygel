AC_PREREQ(2.53)
AC_INIT([rygel],
	m4_esyscmd([GNOME_TAG_PATTERN=RYGEL build-aux/git-version-gen .tarball-version]),
	[http://live.gnome.org/Rygel])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE
AC_CONFIG_SRCDIR([src/rygel/rygel-media-server.vala])
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

VALA_REQUIRED=0.7.3
GUPNP_REQUIRED=0.12.5
GUPNP_AV_REQUIRED=0.4
GUPNP_VALA_REQUIRED=0.5.3
GCONF_REQUIRED=2.16
DBUS_GLIB_REQUIRED=0.74
GSTREAMER_REQUIRED=0.10.22
GIO_REQUIRED=2.16
GEE_REQUIRED=0.1.5
UUID_REQUIRED=1.41.3
LIBSOUP_REQUIRED=2.26.0
GTK_REQUIRED=2.16

PKG_CHECK_MODULES(LIBGUPNP, gupnp-1.0 >= $GUPNP_REQUIRED)
PKG_CHECK_MODULES(LIBGUPNP_AV, gupnp-av-1.0 >= $GUPNP_AV_REQUIRED)
PKG_CHECK_MODULES(LIBGCONF, gconf-2.0 >= $GCONF_REQUIRED)
PKG_CHECK_MODULES(LIBDBUS_GLIB, dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
PKG_CHECK_MODULES(LIBGSTREAMER, gstreamer-0.10 >= $GSTREAMER_REQUIRED)
PKG_CHECK_MODULES(LIBGIO, gio-2.0 >= $GIO_REQUIRED)
PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
PKG_CHECK_MODULES(UUID, uuid >= $UUID_REQUIRED)
PKG_CHECK_MODULES(LIBSOUP, libsoup-2.4 >= $LIBSOUP_REQUIRED)

AC_PATH_PROG(GCONFTOOL, gconftool-2)
AM_GCONF_SOURCE_2

# glib-genmarshal
GLIB_GENMARSHAL=`pkg-config --variable=glib_genmarshal glib-2.0`
AC_SUBST(GLIB_GENMARSHAL)

AC_ARG_ENABLE(vala,
	[  --enable-vala          enable checks for vala],,
        enable_vala=no)

# Vala
if test x$enable_vala = xyes ; then
    # check for vala
    PKG_CHECK_MODULES(VALA, [vala-1.0 >= $VALA_REQUIRED])
    PKG_CHECK_MODULES(GUPNP_VALA, gupnp-vala-1.0 >= $GUPNP_VALA_REQUIRED)

    # Vala compiler
    # This is more to get the path of the compiler since the pkg-config check
    # should covers check for compiler as well.

    AC_PATH_PROG(VALAC, valac, no)

    if test "x$VALAC" = "xno"; then
	AC_MSG_ERROR([Cannot find the "valac" compiler in your PATH])
    fi

    VAPIDIR=`pkg-config --variable=vapidir vala-1.0`

    # FIXME: Whats the proper way for checking for particular Vala bindings
    AC_CHECK_FILE("${VAPIDIR}/gupnp-1.0.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for gupnp-1.0")])

    AC_CHECK_FILE("${VAPIDIR}/gupnp-av-1.0.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for gupnp-av-1.0")])

    AC_CHECK_FILE("${VAPIDIR}/dbus-glib-1.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for dbus-glib-1")])

    AC_CHECK_FILE("${VAPIDIR}/gconf-2.0.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for gconf-2.0")])

    AC_CHECK_FILE("${VAPIDIR}/gstreamer-0.10.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for gstreamer-0.10")])

    AC_CHECK_FILE("${VAPIDIR}/gio-2.0.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for gio-2.0")])

    AC_CHECK_FILE("${VAPIDIR}/gee-1.0.vapi",
                  true,
                  [AC_MSG_ERROR("Unable to find Vala bindings for gee-1.0")])
else
    VAPIDIR=`echo ${datadir}/vala/vapi`
fi

AC_SUBST(VAPIDIR)

# Debugging
AC_ARG_ENABLE(debug,
	[  --enable-debug          enable debugging],,
        enable_debug=no)
if test "x$enable_debug" = "xyes"; then
        CFLAGS="$CFLAGS -g"
fi

# Strict compiler
AC_ARG_ENABLE(strict-cc,
	[  --enable-strict-cc          enable strict C compiler],,
        enable_strict_cc=no)
if test "x$enable_strict_cc" = "xyes"; then
        CFLAGS="$CFLAGS -Wall -Werror"
fi

# Run uninstalled
AC_ARG_ENABLE(uninstalled,
	[  --enable-uninstalled          run uninstalled],,
        enable_uninstalled=no)
if test "x$enable_uninstalled" = "xyes"; then
        AC_MSG_WARN("You want to run the tools uninstalled only? Fine!")
fi

# Check wether user wants to build UIs
AC_ARG_WITH( ui,
  AC_HELP_STRING([--disable-ui],[Don't build UI applications]),
  try_ui=$withval, try_ui=yes )

HAVE_GTK=no
if test x$try_ui = xyes ; then
    dnl check for gtk
    PKG_CHECK_MODULES(GTK, gtk+-2.0 >= $GTK_REQUIRED ,
      [
        AC_SUBST(GTK_CFLAGS)
        AC_SUBST(GTK_LIBS)
        if test x$enable_vala = xyes ; then
                AC_CHECK_FILE("${VAPIDIR}/gtk+-2.0.vapi",
                  [
                        HAVE_GTK=yes
                  ],
                  [
                        HAVE_GTK=no
                        AC_MSG_ERROR("Unable to find Vala bindings for gtk+-2.0")
                  ])
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

# Build test plugin
AC_ARG_ENABLE(test-plugin,
	[  --enable-test-plugin          build test plugin],,
        enable_test_plugin=no)

# Build Tracker plugin
AC_ARG_ENABLE(tracker-plugin,
	[  --enable-tracker-plugin      build tracker plugin],,
        enable_tracker_plugin=yes)

# Build DVB plugin
AC_ARG_ENABLE(dvb-plugin,
	[  --enable-dvb-plugin          build DVB plugin],,
        enable_dvb_plugin=yes)

# Build Folder plugin
AC_ARG_ENABLE(folder-plugin,
	[  --enable-folder-plugin          build Folder plugin],,
        enable_folder_plugin=yes)

# Build External plugin
AC_ARG_ENABLE(external-plugin,
	[  --enable-external-plugin          build External plugin],,
        enable_external_plugin=yes)

# Build Mediathek plugin
AC_ARG_ENABLE(mediathek-plugin,
	[  --enable-mediathek-plugin          build Mediathek plugin],,
        enable_mediathek_plugin=no)


AC_SUBST(abs_top_builddir)

AM_CONDITIONAL([UNINSTALLED], [test "x$enable_uninstalled" = "xyes"])
AM_CONDITIONAL([BUILD_TEST_PLUGIN], [test "x$enable_test_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_TRACKER_PLUGIN],
               [test "x$enable_tracker_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_DVB_PLUGIN], [test "x$enable_dvb_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_MEDIATHEK_PLUGIN], [test "x$enable_mediathek_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_FOLDER_PLUGIN], [test "x$enable_folder_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_EXTERNAL_PLUGIN], [test "x$enable_external_plugin" = "xyes"])

# Gettext
GETTEXT_PACKAGE=rygel
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], 
  [Define the gettext package to be used])

ALL_LINGUAS=""
AM_GLIB_GNU_GETTEXT
AM_GLIB_DEFINE_LOCALEDIR([LOCALEDIR])

AC_OUTPUT([
Makefile
src/Makefile
src/rygel/Makefile
src/ui/Makefile
src/plugins/Makefile
src/plugins/dvb/Makefile
src/plugins/folder/Makefile
src/plugins/external/Makefile
src/plugins/mediathek/Makefile
src/plugins/tracker/Makefile
src/plugins/test/Makefile
data/Makefile
data/xml/Makefile
rygel-1.0.pc
])

echo "

                    ${PACKAGE} ${VERSION}
                    ============


	Prefix:                 ${prefix}
        Source code location:   ${srcdir}
        Compiler:               ${CC}
        CFLAGS:                 ${CFLAGS}
"
