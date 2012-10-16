/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Gee;
using GUPnP;

/**
 * RygelPluginCapabilities is a set of flags that represent various
 * capabilities of plugins.
 */
[Flags]
public enum Rygel.PluginCapabilities {
    /* Server caps */

    /// Server plugin supports upload of images
    IMAGE_UPLOAD,

    /// Server plugin supports upload of video files
    VIDEO_UPLOAD,

    /// Server plugin supports upload of audio files
    AUDIO_UPLOAD,

    /// Server supports upload of all kind of items
    UPLOAD = IMAGE_UPLOAD | VIDEO_UPLOAD | AUDIO_UPLOAD,

    /// Server supports tracking changes
    TRACK_CHANGES

    /* Renderer caps */
}

/**
 * Represents a Rygel plugin. Plugins are supposed to provide an object of this
 * class or a subclass.
 */
public class Rygel.Plugin : GUPnP.ResourceFactory {
    private static const string PNG_EXT = "png";
    private static const string JPG_EXT = "jpg";

    private static const string ICON_BIG = "file://" +
                                           BuildConfig.BIG_ICON_DIR +
                                           "/rygel";
    private static const string ICON_PNG_BIG = ICON_BIG + "." + PNG_EXT;
    private static const string ICON_JPG_BIG = ICON_BIG + "." + JPG_EXT;

    private static const string ICON_SMALL = "file://" +
                                             BuildConfig.SMALL_ICON_DIR +
                                             "/rygel";
    private static const string ICON_PNG_SMALL = ICON_SMALL + "." + PNG_EXT;
    private static const string ICON_JPG_SMALL = ICON_SMALL + "." + JPG_EXT;

    private static const string ICON_PNG_MIME = "image/png";
    private static const string ICON_JPG_MIME = "image/jpeg";

    private static const int ICON_PNG_DEPTH = 32;
    private static const int ICON_JPG_DEPTH = 24;

    private static const int ICON_BIG_WIDTH = 120;
    private static const int ICON_BIG_HEIGHT = 120;
    private static const int ICON_SMALL_WIDTH = 48;
    private static const int ICON_SMALL_HEIGHT = 48;

    public PluginCapabilities capabilities { get; protected set; }

    public string name;
    public string title;
    public string description;

    // Path to description document
    public string desc_path;

    public bool active { get; set; }

    public ArrayList<ResourceInfo> resource_infos;
    public ArrayList<IconInfo> icon_infos;

    public ArrayList<IconInfo> default_icons;

    public Plugin (string  desc_path,
                   string  name,
                   string? title,
                   string? description = null) {
        this.desc_path = desc_path;
        this.name = name;
        this.title = title;
        this.description = description;

        this.active = true;

        if (title == null) {
            this.title = name;
        }

        this.resource_infos = new ArrayList<ResourceInfo> ();
        this.icon_infos = new ArrayList<IconInfo> ();
        this.default_icons = new ArrayList<IconInfo> ();

        // Add PNG icons
        this.add_default_icon (ICON_PNG_MIME,
                               PNG_EXT,
                               ICON_PNG_BIG,
                               ICON_BIG_WIDTH,
                               ICON_BIG_HEIGHT,
                               ICON_PNG_DEPTH);
        this.add_default_icon (ICON_PNG_MIME,
                               PNG_EXT,
                               ICON_PNG_SMALL,
                               ICON_SMALL_WIDTH,
                               ICON_SMALL_HEIGHT,
                               ICON_PNG_DEPTH);

        // Then add JPEG icons
        this.add_default_icon (ICON_JPG_MIME,
                               JPG_EXT,
                               ICON_JPG_BIG,
                               ICON_BIG_WIDTH,
                               ICON_BIG_HEIGHT,
                               ICON_JPG_DEPTH);
        this.add_default_icon (ICON_JPG_MIME,
                               JPG_EXT,
                               ICON_JPG_SMALL,
                               ICON_SMALL_WIDTH,
                               ICON_SMALL_HEIGHT,
                               ICON_JPG_DEPTH);
    }

    public void add_resource (ResourceInfo resource_info) {
        this.resource_infos.add (resource_info);
        this.register_resource_type (resource_info.upnp_type,
                                     resource_info.type);
    }

    public void add_icon (IconInfo icon_info) {
        this.icon_infos.add (icon_info);
    }

    public virtual void apply_hacks (RootDevice device,
                                     string     description_path)
                                     throws Error {
    }

    private void add_default_icon (string mime_type,
                                   string file_extension,
                                   string uri,
                                   int    width,
                                   int    height,
                                   int    depth) {
        var icon = new IconInfo (mime_type, file_extension);
        icon.uri = uri;
        icon.width = width;
        icon.height = height;
        icon.depth = depth;

        this.default_icons.add (icon);
    }
}
