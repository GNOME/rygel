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

.. code-block:: sh

    meson setup build
    ninja -C build

The build is configurable through various build options. Refer to `meson_options.txt <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/meson_options.txt?ref_type=heads>`_
for all available options.

One useful option during development is ``-Duninstalled`` which will allow you run Rygel directly from the ``build`` folder without installing it to your system.

Installing the code
===================

To install what you have built above, just run

.. code-block:: sh

    sudo ninja -C build install

.. toctree::
    :hidden:

    coding-style
    architecture
    debugging

