#! /bin/sh

which gnome-autogen.sh || {
    echo "You need to install gnome-common from the GNOME git"
    exit 1
}

mkdir -p m4

# require automak 1.11 for vala support
REQUIRED_AUTOMAKE_VERSION=1.11 \
REQUIRED_AUTOCONF_VERSION=2.64 \
REQUIRED_LIBTOOL_VERSION=2.2.6 \
REQUIRED_INTLTOOL_VERSION=0.40.0 \
gnome-autogen.sh --enable-vala --enable-maintainer-mode --enable-debug \
                 --enable-strict-valac --enable-tests --enable-test-plugin \
                 --enable-mediathek-plugin --enable-gst-launch-plugin "$@"
