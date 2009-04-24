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

VALA_REQUIRED=0.7.1
GUPNP_REQUIRED=0.12.5
GUPNP_AV_REQUIRED=0.3.2
GUPNP_VALA_REQUIRED=0.5.3
GCONF_REQUIRED=2.16
DBUS_GLIB_REQUIRED=0.74
GSTREAMER_REQUIRED=0.10.22
GIO_REQUIRED=2.16
GEE_REQUIRED=0.1.5
UUID_REQUIRED=1.41.3
LIBSOUP_REQUIRED=2.26.0

PKG_CHECK_MODULES(VALA, [vala-1.0 >= $VALA_REQUIRED])
PKG_CHECK_MODULES(LIBGUPNP, gupnp-1.0 >= $GUPNP_REQUIRED)
PKG_CHECK_MODULES(LIBGUPNP_AV, gupnp-av-1.0 >= $GUPNP_AV_REQUIRED)
PKG_CHECK_MODULES(GUPNP_VALA, gupnp-vala-1.0 >= $GUPNP_VALA_REQUIRED)
PKG_CHECK_MODULES(LIBGCONF, gconf-2.0 >= $GCONF_REQUIRED)
PKG_CHECK_MODULES(LIBDBUS_GLIB, dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
PKG_CHECK_MODULES(LIBGSTREAMER, gstreamer-0.10 >= $GSTREAMER_REQUIRED)
PKG_CHECK_MODULES(LIBGIO, gio-2.0 >= $GIO_REQUIRED)
PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
PKG_CHECK_MODULES(UUID, uuid >= $UUID_REQUIRED)
PKG_CHECK_MODULES(LIBSOUP, libsoup-2.4 >= $LIBSOUP_REQUIRED)

# Vala compiler
# This is more to get the path of the compiler since the pkg-config check
# should covers check for compiler as well.
AC_PATH_PROG(VALAC, valac, no)
if test "x$VALAC" = "xno"; then
	AC_MSG_ERROR([Cannot find the "valac" compiler in your PATH])
fi

VAPIDIR=`pkg-config --variable=vapidir vala-1.0`
AC_SUBST(VAPIDIR)

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

# glib-genmarshal
GLIB_GENMARSHAL=`pkg-config --variable=glib_genmarshal glib-2.0`
AC_SUBST(GLIB_GENMARSHAL)

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

AC_SUBST(abs_top_builddir)

AM_CONDITIONAL([UNINSTALLED], [test "x$enable_uninstalled" = "xyes"])
AM_CONDITIONAL([BUILD_TEST_PLUGIN], [test "x$enable_test_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_TRACKER_PLUGIN],
               [test "x$enable_tracker_plugin" = "xyes"])
AM_CONDITIONAL([BUILD_DVB_PLUGIN], [test "x$enable_dvb_plugin" = "xyes"])

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
src/plugins/Makefile
src/plugins/dvb/Makefile
src/plugins/tracker/Makefile
src/plugins/test/Makefile
data/Makefile
data/xml/Makefile
])

echo "

                    ${PACKAGE} ${VERSION}
                    ============


	Prefix:                 ${prefix}
        Source code location:   ${srcdir}
        Compiler:               ${CC}
        CFLAGS:                 ${CFLAGS}
"
