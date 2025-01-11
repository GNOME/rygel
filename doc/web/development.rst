.. SPDX-License-Identifier: LGPL-2.1-or-later

===========
Development
===========

Overview
========

Rygel is mostly written in `Vala <https://vala.dev/>`_ with the occasional C glue code where required.
Large parts of the code are available via shared-library APIs (such as `librygel-server <https://gnome.pages.gitlab.gnome.org/rygel/api-docs/librygel-server>`_
and `librygel-renderer-gst <https://gnome.pages.gitlab.gnome.org/rygel/api-docs/librygel-renderer-gst>`_)
which are generally expected to be used via the documented C or Vala API.

Rygel is based on `GUPnP <https://gupnp.org>`_. See the `GUPnP API and tutorial documentation <https://gnome.pages.gitlab.gnome.org/gupnp/docs/#extra>`_ and the `GUPnP-AV documentation <https://gnome.pages.gitlab.gnome.org/gupnp-av/docs/>`_.
Rygel's default media engine is based on `GStreamer <https://gstreamer.freedesktop.org/>`_, but developers may `implement alternative Rygel media engines <https://gnome.pages.gitlab.gnome.org/rygel/docs/librygel-server/implementing-media-engines.html>`_
to use other multimedia frameworks.

A slightly more in-depth description of the code structure and program flows can be found at :doc:`architecture documentation<architecture>`.

Getting the source code
=======================

* Rygel development takes place in GitLab `<https://gitlab.gnome.org/GNOME/rygel>`_
* Released tar balls are available from GNOME's FTP server. `<http://ftp.gnome.org/pub/GNOME/sources/rygel/>`_

Getting the dependencies
========================

All dependencies should be available from most distributions. The easiest way would be to use
the distribution's way to get the build dependencies for a specific package, such as

.. code-block:: sh

    apt build-dep rygel

for Debian-based distributions or

.. code-block:: sh

    dnf builddep rygel

for Fedora  etc.

A full list of dependencies can be found in `README.md <https://gitlab.gnome.org/GNOME/rygel/-/blob/master/README.md?ref_type=heads>`_

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

Notes on debugging
==================

Valgrind
--------

* Follow the hints and tricks shown in the `GNOME's developer documentation <https://developer.gnome.org/documentation/tools/valgrind.html>`_
* Use the `suppression file from gstreamer-common <http://cgit.freedesktop.org/gstreamer/common/plain/gst.supp>`_
* Use the `suppression file from GLib <https://gitlab.gnome.org/GNOME/glib/-/raw/main/tools/glib.supp?ref_type=heads>`_
* Use `Rygel's suppression file <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/tools/rygel.supp?ref_type=heads>`_
* Set the environment variable ``RYGEL_PLUGIN_TIMEOUT`` to something very large, for example 9999.

Testing Rygel
=============

UPnP control points known to work with Rygel are the tools from the `GUPnP Tools suite <https://gitlab.gnome.org/GNOME/gupnp-tools>`_ and
`BubbleUPnP for Android <https://play.google.com/store/apps/details?id=com.bubblesoft.android.bubbleupnp&hl=en>`_.

Notes on debugging
==================

Valgrind
--------

* Follow the hints and tricks shown in the `GNOME's developer documentation <https://developer.gnome.org/documentation/tools/valgrind.html>`_
* Use the `suppression file from gstreamer-common <http://cgit.freedesktop.org/gstreamer/common/plain/gst.supp>`_
* Use the `suppression file from GLib <https://gitlab.gnome.org/GNOME/glib/-/raw/main/tools/glib.supp?ref_type=heads>`_
* Use `Rygel's suppression file <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/tools/rygel.supp?ref_type=heads>`_
* Set the environment variable ``RYGEL_PLUGIN_TIMEOUT`` to something very large, for example 9999.

.. toctree::
    :hidden:

    coding-style
    architecture
    integration
