/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copytight (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *         Jens Georg <jensg@openismus.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

/**
  * Holds constants defined by build system.
  */
[CCode (cheader_filename = "config.h")]
public class Rygel.BuildConfig {
    [CCode (cname = "DATA_DIR")]
    public static const string DATA_DIR;

    [CCode (cname = "SYS_CONFIG_DIR")]
    public static const string SYS_CONFIG_DIR;

    [CCode (cname = "DESKTOP_DIR")]
    public static const string DESKTOP_DIR;

    [CCode (cname = "PLUGIN_DIR")]
    public static const string PLUGIN_DIR;

    [CCode (cname = "BIG_ICON_DIR")]
    public static const string BIG_ICON_DIR;

    [CCode (cname = "SMALL_ICON_DIR")]
    public static const string SMALL_ICON_DIR;

    [CCode (cname = "PACKAGE_NAME")]
    public static const string PACKAGE_NAME;

    [CCode (cname = "PACKAGE_VERSION")]
    public static const string PACKAGE_VERSION;

    [CCode (cname = "PACKAGE_STRING")]
    public static const string PACKAGE_STRING;

    [CCode (cname = "GETTEXT_PACKAGE")]
    public static const string GETTEXT_PACKAGE;

    [CCode (cname = "LOCALEDIR")]
    public static const string LOCALEDIR;

    [CCode (cname = "ENGINE_DIR")]
    public static const string ENGINE_DIR;
}
