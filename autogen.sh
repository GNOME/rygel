#! /bin/sh

which gnome-autogen.sh || {
    echo "You need to install gnome-common from the GNOME git"
    exit 1
}

mkdir -p m4
gnome-autogen.sh --enable-vala --enable-maintainer-mode --enable-debug \
                 --enable-test-plugin --enable-mediathek-plugin \
                 --enable-gst-launch-plugin "$@"
