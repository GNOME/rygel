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
    rygel_stamp_files="$rygel_stamp_files $1"
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
