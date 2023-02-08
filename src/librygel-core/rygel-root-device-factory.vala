/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2007 OpenedHand Ltd.
 * Copyright (C) 2012 Openismus GmbH.
 *
 * Authors: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                                <zeeshan.ali@nokia.com>
 *          Jorn Baayen <jorn@openedhand.com>
 *          Jens Georg <jensg@openismus.com>
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

using GUPnP;

namespace Rygel {
    private static string pretty_host_name = null;

    public string get_pretty_host_name () {

        if (pretty_host_name == null) {
            pretty_host_name = Environment.get_host_name ();

            try {
                string machine_info;

                FileUtils.get_contents ("/etc/machine-info", out machine_info);

                var lines = machine_info.split ("\n");

                foreach (var line in lines) {
                    var parts = line.split ("=");

                    if (parts[0] == "PRETTY_HOSTNAME") {
                        pretty_host_name = string.joinv("=", parts[1:parts.length]);
                    }
                }
            } catch (GLib.Error e) {
                debug("Failed to parse /etc/machine-info: %s", e.message);
            }
        }

        return pretty_host_name;
    }
}

/**
 * This is a factory to create #RygelRootDevice objects for
 * a given UPnP context.
 *
 * Call rygel_root_device_factory_create() with a plugin
 * to create a root device for the plugin.
 */
public class Rygel.RootDeviceFactory : Object,
                                       Initable {
    public GUPnP.Context context {get; construct;}

    private Configuration config;

    private string desc_dir;

    public RootDeviceFactory (GUPnP.Context context) throws GLib.Error {
        Object (context : context);
        init ();
    }

    public bool init (Cancellable? cancellable = null) throws GLib.Error {
        if (this.config != null) {
            return true;
        }

        this.config = MetaConfig.get_default ();

        /* We store the modified descriptions in the user's config dir */
        var config_dir = Environment.get_user_config_dir ();
        this.ensure_dir_exists (config_dir);
        this.desc_dir = Path.build_filename (config_dir, "Rygel");
        this.ensure_dir_exists (this.desc_dir);

        return true;
    }

    public RootDevice create (Plugin plugin) throws GLib.Error {
        var desc_path = Path.build_filename (this.desc_dir,
                                             plugin.name + ".xml");
        var template_path = plugin.desc_path;

        /* Create the description xml */
        var doc = this.create_desc (plugin, desc_path, template_path);

        var device = new RootDevice (this.context,
                                     plugin,
                                     doc,
                                     desc_path,
                                     BuildConfig.DATA_DIR);
        plugin.apply_hacks (device, desc_path);

        return device;
    }

    private XMLDoc create_desc (Plugin plugin,
                                string desc_path,
                                string template_path) throws GLib.Error {
        var doc = this.get_latest_doc (desc_path, template_path);

        /* Modify description to include Plugin-specific stuff */

        var file = new DescriptionFile.from_xml_document (doc);

        this.add_services_to_desc (file, plugin);
        this.add_icons_to_desc (file, plugin);

        file.set_friendly_name (this.get_friendly_name (plugin));
        file.set_dlna_caps (plugin.capabilities);
        if (plugin.description != null) {
            file.set_model_description (plugin.description);
        }
        var udn = file.get_udn ();
        if (udn == null || udn == "") {
            // Check if we have a fixed UUID for this plugin
            try {
                udn = this.config.get_string (plugin.name, "uuid");
            } catch (Error error) {
                udn = Uuid.string_random ();
            }
            file.set_udn ("uuid:" + udn);
        }

        file.save (desc_path);

        return doc;
    }

    private string get_friendly_name (Plugin plugin) {
        string title;
        try {
            title = this.config.get_title (plugin.name);
        } catch (GLib.Error err) {
            title = plugin.title;
        }

        title = title.replace ("@REALNAME@", Environment.get_real_name ());
        title = title.replace ("@USERNAME@", Environment.get_user_name ());
        title = title.replace ("@HOSTNAME@", Environment.get_host_name ());
        title = title.replace ("@PRETTY_HOSTNAME@", get_pretty_host_name ());

        return title;
    }

    private void add_services_to_desc (DescriptionFile file,
                                       Plugin plugin) {
        file.clear_service_list ();
        foreach (ResourceInfo resource_info in plugin.resource_infos) {
            // FIXME: We only support plugable services for now
            if (resource_info.type.is_a (typeof (Service))) {
                file.add_service (plugin.name, resource_info);
            }
        }
    }

    private void add_icons_to_desc (DescriptionFile file,
                                    Plugin plugin) {
        var icons = plugin.icon_infos;

        if (icons == null || icons.size == 0) {
            debug ("No icon provided by plugin '%s'. Using Rygel logo.",
                   plugin.name);

            icons = plugin.default_icons;
        }

        file.clear_icon_list ();
        foreach (var icon in icons) {
            var remote_path = this.get_icon_remote_path (icon, plugin);
            if (icon.uri.has_prefix ("file://")) {
                var local_path = icon.uri.substring (7);
                this.context.host_path (local_path, remote_path);
            }

            file.add_icon (plugin.name, icon, remote_path);
        }
    }

    private string get_icon_remote_path (IconInfo icon_info,
                                         Plugin plugin) {
        if (icon_info.uri.has_prefix ("file://")) {
            // /PLUGIN_NAME-WIDTHxHEIGHTxDEPTH.png
            return "/" + plugin.name + "-" +
                   icon_info.width.to_string () + "x" +
                   icon_info.height.to_string () + "x" +
                   icon_info.depth.to_string () + "." +
                   icon_info.file_extension;
        } else {
            var uri = icon_info.uri;
            uri.replace ("@ADDRESS@", this.context.address.to_string ());
            return uri;
        }
    }

    private XMLDoc get_latest_doc (string path1,
                                   string path2) throws GLib.Error {
        var file = File.new_for_path (path1);
        if (!file.query_exists (null)) {
            return new XMLDoc.from_path (path2);
        }

        var info = file.query_info (FileAttribute.TIME_MODIFIED,
                                    FileQueryInfoFlags.NONE);
        var mod1 = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);

        file = File.new_for_path (path2);
        info = file.query_info (FileAttribute.TIME_MODIFIED,
                                FileQueryInfoFlags.NONE);
        var mod2 = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);

        if (mod1 > mod2) {
            // If we fail to load the derived description file, try the
            // template instead.
            try {
                return new XMLDoc.from_path (path1);
            } catch (Error error) {
                return new XMLDoc.from_path (path2);
            }
        } else {
            return new XMLDoc.from_path (path2);
        }
    }

    private void ensure_dir_exists (string dir_path) throws Error {
        DirUtils.create_with_parents (dir_path, 0750);
    }
}
