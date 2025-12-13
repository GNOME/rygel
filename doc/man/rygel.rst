.. SPDX-License-Identifier: LGPL-2.1-or-later
.. rygel(1):

=====
rygel
=====

----------------------------------
A collection of DLNA/UPnP services
----------------------------------

:Manual section: 1

SYNOPSIS
========
    **rygel \[options\]**

DESCRIPTION
===========
**Rygel** is a home media solution that allows you to easily share audio, video and
pictures, and control of media player on your home network. In technical terms
it is both a UPnP AV MediaServer and MediaRenderer implemented through a
plug-in mechanism. Interoperability with other devices in the market is
achieved by conformance to very strict requirements of DLNA and on the fly
conversion of media to format that client devices are capable of
handling.

OPTIONS
=======

The program follows the usual GNU command line syntax, with long options starting with two dashes \('-'\). A summary of options is included below.

--help, -h
    Show summary of options.

--version
    Show version of program.

--network-interface=INTERFACE, -n

    Set the network interfaces rygel listens on. Can be used multiple times for to configure multiple interfaces.  INTERFACE can be an IP, a device name or an ESSID (Linux only).

--port=PORT, -p
    Set the listen-port.

--disable-transcoding, -t
    Disable any transcoding.

--disallow-upload, -U
    Disable uploading of media files via UPnP.

--disallow-deletion, -D
    UPnP clients are not allowed to delete media files on the server.

--log-level=LEVEL, -g
    Comma-separated list of DOMAIN:LEVEL pairs, allowing to set the log level individually for each domain, where DOMAIN is either "*", "rygel" or the name of a plugin. Allowed log levels are 1=critical, 2=error, 3=warning,
    4=message/info, 5=debug.

--plugin-path=PATH, -u
    Set the plugin search path.

--engine-path=ENGINE_PATH, -e
    Set the media streaming and transcoding engine search path.

--disable-plugin=PLUGIN_NAME, -d
    Disable the plugin PLUGIN_NAME.

--title=TITLE_DESCRIPTION, -i
    TITLE_DESCRIPTION is a colon-separated pair of PLUGIN_NAME:TITLE. It sets the title of plugin PLUGIN_NAME to TITLE. You can use this option more than once for every plugin you want to set the name of multiple plugins.

--plugin-option=PLUGIN_OPTION_STRING, -o
    Set options for a plugin. PLUGIN_OPTION_STRING has the format PLUGIN_NAME:OPTION:VALUE1[,VALUE2,...]

--config=CONFIG_FILE, -c
    Use CONFIG_FILE instead of ``${XDG_CONFIG_DIR}/rygel.conf.``

--shutdown, -s
    Shutdown a currently running instance of rygel

--replace, -r
    Replace the currently running instance of rygel with this instance. Short for rygel -s && rygel

FILES
=====

/etc/rygel.conf
    The system-wide configuration file to control the behavior of rygel. See rygel.conf(5) for further details.

``${XDG_CONFIG_DIR}/rygel.conf``
    The per-user configuration file to control the behavior of rygel. See rygel.conf(5) for further details.

``${XDG_CONFIG_DIR}/Rygel/*.xml``
    Cached UPnP device description files.

ENVIRONMENT
===========

RYGEL_IFACE
    Set the network interfaces to bind to.

RYGEL_PORT
    Define the network port to bind to.

RYGEL_DISABLE_TRANSCODING
    Disable transcoding globally.

RYGEL_LOG
    Set the log level of rygel.

RYGEL_PLUGIN_PATH
    Set the plugin search path of rygel.

RYGEL_ENGINE_PATH
    Set the media streaming and transcoding engine search path for rygel.

RYGEL_MEDIA_ENGINE
    Set a specific media streaming engine to pick up from the media engine search path.

RYGEL_DISABLE_UPLOAD
    Disable media file upload via UPnP.

RYGEL_DISABLE_DELETION
    Disable remote file deletion via UPnP.

RYGEL_PLUGIN_TIMEOUT
    Set the time-out for finding the plugins. Useful to increase when running inside valgrind.

RYGEL_DATABASE_DEBUG
    If set to 1, the database library will print the used SQL statements.

Also for every plugin you can set the following environment variables:

RYGEL_PLUGIN_NAME_TITLE
    Set the title of the plugin.

RYGEL_PLUGIN_NAME_ENABLED
    Enable or disable the plugin.

BUGS
====

The BTS can be found at `GNOME's Gitlab <https://gitlab.gnome.org/GNOME/rygel/issues>`__.

SEE ALSO
========

``rygel.conf(5)``
