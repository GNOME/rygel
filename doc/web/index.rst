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

You can report issues

Developer Features
==================

Rygel provides several shared libraries in addition to the main Rygel server and its plugins. These may
be used to implement Rygel plugins or media engines, standalone renderers, or even to implement
replacement UPnP/DLNA servers.

* librygel-server
* librygel-core
* librygel-db
* librygel-renderer
* librygel-renderer-gst

Development
===========

For details on building Rygel on your own, refer to the :doc:`development documentation<development>`.

Installing
==========

Rygel should be available for all major distributions. If you opt building from source, see the :doc:`development documentation<development>`.

.. toctree::
    :hidden:

    development
    installing
    contact
    features
    faq
