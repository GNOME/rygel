.. SPDX-License-Identifier: LGPL-2.1-or-later

=======
Plugins
=======

Rygel provides its functionality through plugins. There are several different media servers and renderers available


Media renderers
===============

MPRIS
-----

The MPRIS plug-in enables out-of-the-box UPnP rendering capabilities for a variety of media players. Using the
`MPRIS D-Bus interface specification <http://specifications.freedesktop.org/mpris-spec/latest/>`_ for media player remote
control, it converts UPnP remote calls to MPRIS calls and vice-versa, turning your favourite media players such as Totem,
Rhythmbox, VLC etc. into UPnP rendering devices.

Refer to the :ref:`mpris_configuration` document for plugin-specific options.

Playbin
-------

Playbin is a simple UPnP renderer plug-in which is based on GSteamer's PlayBin3 element. Although being fairly compatible
with regard to the UPnP and DLNA specifications, it lacks (partially on purpose) on the UI side. There is no full-screen
support or automatic disabling of the screensaver.

Refer to the :ref:`playbin_configuration` document for plugin-specific options.

Media servers
=============

MediaExport
-----------

The Media Export plugin recursively exports folders and files specified in the user configuration. This plugin supports all
types of URIs that gio/gvfs and gstreamer can handle. This plugin uses gupnp-dlna's APIs directly to extract metadata from
media and thus does *not* use Tracker.

This plugin may not be used at the same time as the Tracker plugin because both serve a similar purpose.

Tracker
-------

Rygel's Tracker plugin use Tracker to discover media files and export them via UPnP.

This plugin may not be used at the same time as the Media Export plugin because both serve a similar purpose.

GstLaunch
---------

TBD

External
--------

Programs can expose a D-Bus hierarchy on org.gnome.MediaServer2.ApplicationName, which Rygel will pick up and
convert into a DLNA server.

For details on the required D-Bus specification details, refer to :doc:`the MediaServer2 specification<media-server2>`

.. _Plugins Media Engines:

Media engines
-------------

GStreamer
^^^^^^^^^

Rygel's GStreamer media engine uses the streaming, transcoding and seeking abilities of the GStreamer framework, which is available on most platforms.

The source format may be anything GStreamer's decodebin can handle. The supported output formats are:

* Audio:
    * MP3
    * LPCM
    * AAC
* Video:
    * MPEG TS
    * WMV version 1 (mainly for XBox 360 compatability)
    * H.264 baseline with AAC audio in MP4 container

Simple media engine
^^^^^^^^^^^^^^^^^^^

The Simple media engine uses no multimedia framework and therefore offers no transcoding or time-based seeking.
