#! /bin/sh

which gnome-autogen.sh || {
    echo "You need to install gnome-common from the GNOME git"
    exit 1
}

mkdir -p m4

# require automak 1.11 for vala support
export REQUIRED_AUTOMAKE_VERSION=1.11
gnome-autogen.sh --enable-vala --enable-maintainer-mode --enable-debug \
                 --enable-test-plugin --enable-mediathek-plugin \
                 --enable-gst-launch-plugin "$@"
