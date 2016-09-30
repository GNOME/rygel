/*
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gee;
using GUPnP;

/**
 * RygelPluginCapabilities is a set of flags that represent various
 * capabilities of plugins.
 */
[Flags]
public enum Rygel.PluginCapabilities {
    NONE = 0,
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
    TRACK_CHANGES,

    /// Server supports container creation
    CREATE_CONTAINERS,

    /* Renderer caps */

    /// General capabilities

    /* Diagnostics (DIAGE) support */
    DIAGNOSTICS,

    /* EnergyManagement (LPE) support */
    ENERGY_MANAGEMENT
}

/**
 * This represents a Rygel plugin.
 *
 * Plugin libraries should provide an object of this
 * class or a subclass in their module_init() function.
 *
 * It is generally convenient to derive from 
 * #RygelMediaRendererPlugin from librygel-renderer,
 * or from #RygelMediaServerPlugin from librygel-server.
 *
 * Plugins may change their behaviour based on their
 * configuration. See rygel_meta_config_get_default().
 */
public class Rygel.Plugin : GUPnP.ResourceFactory {
    private const string PNG_EXT = "png";
    private const string JPG_EXT = "jpg";

    private const string ICON_BIG = "file://" +
                                           BuildConfig.BIG_ICON_DIR +
                                           "/rygel";
    private const string ICON_PNG_BIG = ICON_BIG + "." + PNG_EXT;
    private const string ICON_JPG_BIG = ICON_BIG + "." + JPG_EXT;

    private const string ICON_SMALL = "file://" +
                                             BuildConfig.SMALL_ICON_DIR +
                                             "/rygel";
    private const string ICON_PNG_SMALL = ICON_SMALL + "." + PNG_EXT;
    private const string ICON_JPG_SMALL = ICON_SMALL + "." + JPG_EXT;

    private const string ICON_PNG_MIME = "image/png";
    private const string ICON_JPG_MIME = "image/jpeg";

    private const int ICON_PNG_DEPTH = 24;
    private const int ICON_JPG_DEPTH = 24;

    private const int ICON_BIG_WIDTH = 120;
    private const int ICON_BIG_HEIGHT = 120;
    private const int ICON_SMALL_WIDTH = 48;
    private const int ICON_SMALL_HEIGHT = 48;

    public PluginCapabilities capabilities { get; construct set; }

    public string name { get; construct; }
    public string title { get; construct set; }
    public string description { get; construct; }

    // Path to description document
    public string desc_path { get; construct; }

    public bool active { get; set; }

    public ArrayList<ResourceInfo> resource_infos { get; private set; }
    public ArrayList<IconInfo> icon_infos { get; private set; }

    public ArrayList<IconInfo> default_icons { get; private set; }

    /*
     * TODO: Document the format of the template file, such as which tags/attributes
     * should be present, which should be present but empty, and which
     * tags should not be present.
     */

    /** 
     * Create an instance of the plugin.
     *
     * @param desc_path The path of a template file for an XML description of the UPnP service.
     * @param name The non-human-readable name for the plugin and its service, used in UPnP messages and in the Rygel configuration file.
     * @param title An optional human-readable name (friendlyName) of the UPnP service provided by the plugin. If the title is empty then the name will be used.
     * @param description An optional human-readable description (modelDescription) of the UPnP service provided by the plugin.
     */
    public Plugin (string  desc_path,
                   string  name,
                   string? title,
                   string? description = null,
                   PluginCapabilities capabilities = PluginCapabilities.NONE) {
        Object (desc_path : desc_path,
                name : name,
                title : title,
                description : description,
                capabilities : capabilities);
    }

    public override void constructed () {
        base.constructed ();

        this.active = true;

        if (this.title == null) {
            this.title = this.name;
        }

        this.resource_infos = new ArrayList<ResourceInfo> ();

        /* Enable BasicManagement service on this device if needed */
        var config = MetaConfig.get_default ();
        try {
            if (config.get_bool (this.name, "diagnostics")) {
                var resource = new ResourceInfo (BasicManagement.UPNP_ID,
                                                 BasicManagement.UPNP_TYPE,
                                                 BasicManagement.DESCRIPTION_PATH,
                                                 typeof (BasicManagement));
                this.add_resource (resource);

                this.capabilities |= PluginCapabilities.DIAGNOSTICS;
            }
        } catch (GLib.Error error) {
            if (!(error is ConfigurationError.NO_VALUE_SET))
                warning ("Failed to read configuration: %s", error.message);
        }

        /* Enable EnergyManagement service on this device if needed */
        config = MetaConfig.get_default ();
        try {
            if (config.get_bool (this.name, "energy-management")) {
                var resource = new ResourceInfo (EnergyManagement.UPNP_ID,
                                                 EnergyManagement.UPNP_TYPE,
                                                 EnergyManagement.DESCRIPTION_PATH,
                                                 typeof (EnergyManagement));
                this.add_resource (resource);

                this.capabilities |= PluginCapabilities.ENERGY_MANAGEMENT;

            }
        } catch (GLib.Error error) {
            if (!(error is ConfigurationError.NO_VALUE_SET))
                warning ("Failed to read configuration: %s", error.message);
        }

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
