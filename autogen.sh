#! /bin/sh
mkdir -p m4
autoreconf -v --install || exit 1
glib-gettextize --force --copy || exit 1
./configure --enable-vala --enable-maintainer-mode --enable-debug \
            --enable-test-plugin --enable-mediathek-plugin \
	    --enable-gstlaunch-plugin "$@"
