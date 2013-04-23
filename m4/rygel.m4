dnl rygel.m4
dnl
dnl Copyright 2011 Jens Georg
dnl
dnl This library is free software; you can redistribute it and/or
dnl modify it under the terms of the GNU Lesser General Public
dnl License as published by the Free Software Foundation; either
dnl version 2.1 of the License, or (at your option) any later version.
dnl
dnl This library is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl Lesser General Public License for more details.
dnl
dnl You should have received a copy of the GNU Lesser General Public
dnl License along with this library; if not, write to the Free Software
dnl Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

AC_DEFUN([RYGEL_ADD_STAMP],
[
    rygel_stamp_files="$rygel_stamp_files $srcdir/$1"
])

AC_DEFUN([RYGEL_ADD_VALAFLAGS],
[
    VALAFLAGS="${VALAFLAGS:+$VALAFLAGS }$1"
])

# RYGEL_CHECK_PACKAGES(LIST-OF-PACKAGES,
#   ACTION-IF-FOUND)
# ---------------------------------------
# Version of VALA_CHECK_PACKAGES that will only run if vala support is
# enabled. Otherwise ACTION-IF-FOUND will be run.
AC_DEFUN([RYGEL_CHECK_PACKAGES],
[
    AS_IF([test "x$enable_vala" = "xyes"],
          [
                VALA_CHECK_PACKAGES([$1],[$2])
          ],
          [
                $2
          ])
])

# _RYGEL_ADD_PLUGIN_INTERNAL(NAME-OF-PLUGIN,
#   NAME-OF-PLUGIN-WITH-UNDERSCORES,
#   NAME-OF-PLUGIN-FOR-HELP,
#   DEFAULT-FOR-ENABLE)
# --------------------------------------
# Add an --enable-plugin option, add its Makefile to AC_OUTPUT and set the
# conditional
AC_DEFUN([_RYGEL_ADD_PLUGIN_INTERNAL],
[
    AC_ARG_ENABLE([$1-plugin],
        AS_HELP_STRING([--enable-$1-plugin],[enable $3 plugin]),,
        enable_$2_plugin=$4)
    AC_CONFIG_FILES([src/plugins/$1/Makefile])
    AM_CONDITIONAL(m4_toupper(build_$2_plugin), test "x$[]enable_$2_plugin" = "xyes")
    RYGEL_ADD_STAMP([src/plugins/$1/librygel_$2_la_vala.stamp])
    AC_CONFIG_FILES([src/plugins/$1/$1.plugin])
])

# _RYGEL_ADD_PLUGIN_INTERNAL(NAME-OF-PLUGIN,
#   NAME-OF-PLUGIN-FOR-HELP,
#   DEFAULT-FOR-ENABLE)
# --------------------------------------
# Add an --enable-plugin option, add its Makefile to AC_OUTPUT and set the
# conditional
AC_DEFUN([RYGEL_ADD_PLUGIN],
[
    _RYGEL_ADD_PLUGIN_INTERNAL([$1],
        m4_translit([$1],[-],[_]),
        [$2],
        [$3])
])

AC_DEFUN([_RYGEL_DISABLE_PLUGIN_INTERNAL],
[
    AM_CONDITIONAL(m4_toupper(build_$1_plugin), false)
    enable_$1_plugin="n/a"
])

AC_DEFUN([RYGEL_DISABLE_PLUGIN],
[
    _RYGEL_DISABLE_PLUGIN_INTERNAL(m4_translit([$1],[-],[_]))
])

AC_DEFUN([RYGEL_CHECK_VALA],
[
    AC_ARG_ENABLE([vala],
        [AS_HELP_STRING([--enable-vala],[enable checks for vala])],,
            [enable_vala=no])
    AC_ARG_ENABLE([strict-valac],
        [AS_HELP_STRING([--enable-strict-valac],[enable strict Vala compiler])],,
              [enable_strict_valac=no])
    AS_IF([test "x$enable_strict_valac" = "xyes"],
          [RYGEL_ADD_VALAFLAGS([--fatal-warnings])])
    AC_SUBST([VALAFLAGS])

    dnl Enable check for Vala even if not asked to do so if stamp files are absent.
    for stamp in $rygel_stamp_files
    do
        AS_IF([test ! -e "$stamp"],
              [AC_MSG_WARN([Missing stamp file $[]stamp. Forcing vala mode])
               enable_vala=yes
              ])
    done

    dnl Vala
    AS_IF([test x$enable_vala = xyes],
          [dnl check for vala
           AM_PROG_VALAC([$1])

            AS_IF([test x$VALAC = "x"],
                [AC_MSG_ERROR([Cannot find the "valac" compiler in your PATH])],
                [
                    VALA_CHECK_PACKAGES([$2])
                ])
           ],
           []
    )

    VAPIDIR="${datadir}/vala/vapi"
    AC_SUBST(VAPIDIR)
])
