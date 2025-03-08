.. SPDX-License-Identifier: LGPL-2.1-or-later

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

TBD

Configuration files
===================

The main configuration of Rygel is done through two files. The user-specific documentation in,
``$XDG_CONFIG_HOME/rygel.conf`` and the system-wide configuration in ``/etc/rygel.conf``.
Settings in the user-specific configuration override the settings in the system-wide configuration.

A default configuration file can be found `here <https://gitlab.gnome.org/GNOME/rygel/-/raw/master/data/rygel.conf?ref_type=heads>`_.

.. include:: config-file.rst
