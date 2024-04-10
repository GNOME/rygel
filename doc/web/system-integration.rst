.. SPDX-License-Identifier: LGPL-2.1-or-later

==================
System integration
==================

systemd
=======

It is recommended to run Rygel either through GNOME settings's media sharing option or, for example on headless devices,
as a user service in a lingering session. A sample user service file is available `here <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/data/rygel.service.in?ref_type=heads>`_
but should also be installed in your system.

Pulseaudio
==========

It is possible to distribute a computer's audio via DLNA. For Pulseaudio, two ways are possible:

Native Pulseaudio integration
-----------------------------

Pulseaudio needs to load module-http-protocol-tcp for this to work. Additionally, using e.g. paprefs,
"Make local sound devices available as DLNA/UPnP Media Server" must be enabled on Pulseaudio.

Afterwards, enabable the External plugin and explicitly enable the Pulseaudio peer with this configuration:

.. code:: ini

    [External]
    enabled=true

    [org.gnome.UPnP.MediaServer2.PulseAudio]
    enabled=true

Using GstLaunch
---------------

While it is easier to enable the "Create separate audio device for DLNA/UPnP media streaming" option in
pulseaudio, this works with any monitor for any available audio device.

Using the snippet below, the host's audio will be available to DLNA as a FLAC stream:

.. code:: ini

    [GstLaunch]
    enabled=true
    launch-items=myaudioflac

    myaudioflac-title=FLAC audio on @HOSTNAME@
    myaudioflac-mime=audio/flac
    myaudioflac-launch=pulsesrc device=upnp.monitor ! flacenc

It is also possible to provide additional formats, like

.. code:: ini

    [GstLaunch]
    enabled=true
    launch-items=myaudiomprg
    myaudioflac-title=FLAC audio on @HOSTNAME@
    myaudioflac-mime=audio/flac
    myaudioflac-launch=pulsesrc device=upnp.monitor ! audio/x-raw,channels=2 ! flacenc

    myaudiompeg-title=mpeg audio on @HOSTNAME@
    myaudiompeg-mime=audio/mpeg
    myaudiompeg-launch=pulsesrc device=upnp.monitor ! audio/x-raw,channels=2 ! lamemp3enc target=quality quality=6
