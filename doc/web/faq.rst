.. SPDX-License-Identifier: LGPL-2.1-or-later

===
FAQ
===

Rygel seems unwilling to bind to any interface other than 127.0.0.1, despite -n or interfaces=
==============================================================================================

A symptom for this problem is that you can not see the Rygel server on your network. You can confirm
that this is an issue by running Rygel with debug output, and look for lines like this:

::

  (rygel:4791): Rygel-DEBUG: rygel-main.vala:137: New network 127.0.0.0 (lo) context available. IP: 127.0.0.1

If you only get the above line, and nothing about eth0 or wlan0 (in addition to lo), or any other
interface, this indicates that you are using GUPnP which is compiled with the NetworkManager context
manager and NetworkManager is running, but you're not using it for global device configuration but
relying on e.g. :code:`/etc/network/interfaces`. Possible solutions

* Switch to NetworkManager.
* Recompile GUPnP with the "linux" context manager.

Rygel keeps changing its UUID on every start
============================================

Make sure that your system time is set correctly and not to a point in the past. Otherwise Rygel will
think that its device description templates have been updated and when device descriptions are updated
it will start with a fresh UUID. You can verify whether this is the issue or not by issuing

::

  [ $(stat -c %Y /usr/share/rygel/xml/MediaServer3.xml) -gt  $(date +%s) ] \
      && echo "System time older than template mtime"


Also make sure that the home directory of the user running Rygel is on a non-volatile file-system
(More specifically, :code:`XDG_CONFIG_HOME` needs to be on a non-volatile file-system).

Lastly, it is also possibly to override the UUID in :code:`rygel.conf`. See its manpage for details.

Rygel does not find any of its plugins
======================================

If you compiled rygel from scratch inside jhbuild or similar environment, make sure you have
shared-mime-info installed as well. Otherwise the plugin detection will not work (and the MediaExport
plugin will have problems as well)

Rygel is only seen by other devices when started but cannot be found otherwise
==============================================================================

If you're running Rygel on a bridge network device (brX), try to disable IGMP snooping. If that's not
the case, please file a bug against GSSDP including a packet capture.

In certain environments, MediaExport's meta-data extracting helper binary seems to lock up on start-up.
This is related to libmediaart starting volume monitors. There is no solution to this yet. Installing
GVFS and having a D-Bus session bus is reported to help on some occasions.
