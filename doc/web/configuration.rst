.. SPDX-License-Identifier: CC-BY-SA-4.0

=============
Configuration
=============

Configuration in Rygel can be accomplished through several mechanisms with different priorities.
Configuration can be done, in descending order of precendence, through:

1. Environment variables
2. Command line arguments
3. User configuration
4. System-wide configuration

All configuration options are available in all configuration mechanisms.

Environment variables
=====================

Special environment variables for everything
--------------------------------------------

.. include:: environment.rst

Generic configuration settings
------------------------------

It is possible to override all settings using config variables. The pattern here is ``RYGEL_``,
followed by the name of the plugin in uppercase, followed by the name of the config option with
``-`` replaced by ``_``.

Examples
^^^^^^^^

Disabling meta-data extraction in MediaExport
    ``RYGEL_MEDIAEXPORT_EXTRACT_METADATA=false``

Only allow transcoding to MP3:
    ``RYGEL_GSTMEDIAENGINE_TRANSCODERS=mp3``

Turn off IPv6 temporarily
    ``RYGEL_GENERAL_IPV6=0``

Configuration files
===================

The main configuration of Rygel is done through two files. The user-specific documentation in,
``$XDG_CONFIG_HOME/rygel.conf`` and the system-wide configuration in ``/etc/rygel.conf``.
Settings in the user-specific configuration override the settings in the system-wide configuration.

A default configuration file can be found `here <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/data/rygel.conf?ref_type=heads>`_.

.. include:: config-file.rst
