.. SPDX-License-Identifier: LGPL-2.1-or-later
.. image:: img/rygel-full.svg
   :alt: Logo of Rygel
   :scale: 75%

=====
Rygel
=====

Rygel is a home media solution (UPnP AV MediaServer) that allows you to easily share audio, video and pictures to other devices.

Additionally, media player software may use Rygel to become a MediaRenderer that may be controlled remotely by a UPnP or DLNA Controller.

Rygel achieves interoperability with other devices in the market by trying to conform to the very strict requirements of DLNA and by converting media on-the-fly to formats that client devices can handle.

Most Rygel functionality is implemented through a plug-in mechanism.

User Features
=============

There are many DLNA/UPnP devices on the market, such as the major gaming consoles from various generations, DLNA speakers, and many of the Smart TVs on the market. Rygel allows a user to:

* Browse and play media stored on a PC via a TV or PS3, even if the original content is in a format that the TV or PS3 cannot play.
* Easily search and play media using a phone, TV, or PC.
* Redirect sound output to DLNA speakers.

For more details, refer to :doc:`plugins documentation<plugins>`.

Contact
=======

For general discussion, please use the `Rygel tag at GNOME's Discourse <https://discourse.gnome.org/tag/rygel>`_ or join `our Matrix room <https://matrix.to/#/#gupnp:gnome.org>`_.
If you encounter any problems you believe are bugs in Rygel, please `open a new issue in Gitlab <https://gitlab.gnome.org/GNOME/rygel/issues/new?issue%5Bassignee_id%5D=&issue%5Bmilestone_id%5D=>`_,
but please check the `list of existing issues <https://gitlab.gnome.org/GNOME/rygel/-/issues/?sort=created_date&state=opened>`_ beforehand.

Developer Features
==================

Rygel provides several shared libraries in addition to the main Rygel server and its plugins. These may
be used to implement Rygel plugins or media engines, standalone renderers, or even to implement
replacement UPnP/DLNA servers.

* Basic infrastructure and UPnP-AV plumbing - `librygel-core <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-core/>`_
* Generalized SQLite access helper - `librygel-db <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-db/>`_
* Implementing an UPnP-AV server - `librygel-server <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-server/>`_
* Implementing an UPnP-AV renderer - `librygel-renderer <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-renderer/>`_
* Helpers if the UPnP-AV renderer is going to be based on GStreamer - `librygel-renderer-gst <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-renderer-gst>`_
* Implementing an UPnP Remote UI server - `librygel-ruih <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-ruih>`_

Development
===========

For details on building Rygel on your own, refer to the :doc:`development documentation<development>`.

Installing
==========

Rygel should be available for all major distributions. If you choose to build it from source yourself, see the :doc:`development documentation<development>`.

Further refinement can be done through the :doc:`system and user configuration <configuration>`.

.. toctree::
    :maxdepth: 1
    :hidden:

    plugins
    configuration
    development
    faq
    troubleshooting
    system-integration
