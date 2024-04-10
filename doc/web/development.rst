.. SPDX-License-Identifier: LGPL-2.1-or-later

===========
Development
===========

Getting the source code
=======================

* Rygel development takes place in GitLab `<https://gitlab.gnome.org/GNOME/rygel>`_
* Released tar balls are available from GNOME's FTP server. `<http://ftp.gnome.org/pub/GNOME/sources/rygel/>`_

Building the code
=================

::

    meson setup build
    ninja -C build
    ninja -C build install

The build is configurable through various build options. Refer to `meson_options.txt <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/meson_options.txt?ref_type=heads>`_
for all available options.

One useful option during development is `-Duninstalled` which will allow you run Rygel from the build folder


