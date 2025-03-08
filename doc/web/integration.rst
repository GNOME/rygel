.. SPDX-License-Identifier: LGPL-2.1-or-later

===========
Integration
===========

Rygel provides full server and renderer functionality by default, using `LocalSearch/TinySPARQL <https://tracker.gnome.org/>`_ and `GStreamer <https://gstreamer.freedesktop.org>`_.
However, one might encounter situations where it is necessary to integrate Rygel with a new or unusual platform, or to customize Rygel somehow.

Integration Rygel as a Media Server (DMS)
=========================================

Server Plugins
--------------

For the available implementations, see the :doc:`Plugins <plugins>` documentation. They may be enabled or disabled in the :doc:`Configuration <configuration>`.

It is also possible to `implement your own server plugin <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-server/implementing-server-plugins.html>`_
instead, for instance to provide media that has been discovered by your platform's own file indexing system.

Media engines
-------------

Rygel also provides a choice of :ref:`Plugins Media Engines`, through it defaults to using a GStreamer-based media-engine. Your Rygel configuration
should specify which media engine should be used, and how it should be used.

You may also `implement your own media engine <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-server/implementing-media-engines.html>`_ instead,
to use a multimedia framework provided by your platform. This may be neccessary due to licensing/patent issues, or to make the best use of hardware codecs.

Standalone servers
------------------

You may also use Rygel's API to `implement your own media server <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-server/implementing-servers.html>`_,
instead of running the rygel binary.

Using Rygel to implement an UPnP/DLNA Renderer or Player
========================================================

Althought Rygel is primarily a media server, it provides a librygel-renderer API to help with the
`implementation <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-renderer/implementing-renderers.html>`_ (or adaptation) of software,
such as media players, that can be UPnP or DLNA media renderers or players.

For platforms that use GStreamers, Rygel provides the more specialized librygel-renderer-gst API to `implement the renderer/player functionality with Rygel/GStreamer <https://gnome.pages.gitlab.gnome.org/rygel/reference/gtkdoc/librygel-renderer-gst/implementing-renderers-gst.html>`_
