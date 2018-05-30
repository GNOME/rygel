What is Rygel?
=============

Rygel is a home media solution that allows you to easily share audio, video and
pictures, and control of media player on your home network. In technical terms
it is both a UPnP AV MediaServer and MediaRenderer implemented through a plug-in
mechanism. Interoperability with other devices in the market is achieved by
conformance to very strict requirements of DLNA and on the fly conversion of
media to format that client devices are capable of handling.

Important facts and features
============================

  * Based on GUPnP.
  * Written largely in Vala language.
  * Provides APIs to ease the implementation of AV devices.
  * Export of on-disk media:
    * Tracker plugin.
    * MediaExport plugin: Recursively exports folders and files specified in the user configuration. This plugin supports all types of URIs that gio/gvfs and gstreamer can handle.
  * Export of media hierarchies provided by external applications through
    implementation of D-Bus MediaServer spec. Applications that utilize
    this feature are:
    * DVB Daemon
    * Rhythmbox
  * Export of GStreamer pipelines as media items on the network, specified
    through gst-launch syntax in the user configuration.
  * Audio and Video Transcoding: source format could be anything GStreamer's
    decodebin2 can handle but output formats are currently limited to: mp3, PCM
    and MPEG TS. Fortunately the transcoding framework is flexible enough to
    easily add more transcoding targets.
  * Standalone MediaRenderer plugin based on GStreamer playbin element.
  * Export of media players that implement MPRIS2 D-Bus interface, as
    MediaRenderer devices. Known implementing applications are:
    * Rhythmbox
    * VLC

Requirements
============

  * Build-time:
    * Core:
      * gupnp
      * gupnp-av
      * gstreamer
      * gio (part of glib source package)
      * libgee
      * libsoup
      * libmediaart
      * vala (not if building from release tarballs)
    * Preferences UI:
      * gtk+
    * MediaExport:
      * sqlite3
      * gupnp-dlna
  * Run-time:
    * Definitely needed:
      * gst-plugins-base
      * shared-mime-info
    * Might be needed (depending on your usage and media collection):
      * gst-plugins-good
      * gst-libav
      * gst-plugins-bad
      * gst-plugins-ugly

To build without gstreamer, use ```--with-media-engine=simple``` during configure time.
This will also disable any plugins that use gstreamer.

References
==========

  * http://www.dlna.org
  * http://www.upnp.org
  * http://www.gupnp.org
  * http://www.vala-project.org
  * http://www.wikipedia.org/wiki/Media_server
  * http://www.upnp.org/specs/av/UPnP-av-MediaServer-v2-Device-20060531.pdf
  * https://wiki.gnome.org/Projects/Tracker
  * https://wiki.gnome.org/Projects/DVBDaemon
  * https://wiki.gnome.org/Projects/Rygel/MediaServer2Spec
  * http://www.mpris.org/2.0/spec/

