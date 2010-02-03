/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using GUPnP;
using CStuff;

public errordomain RootDeviceFactoryError {
    XML_PARSE,
}

/**
 * Factory for RootDevice objects. Give it a plugin and it will create a
 * Root device for that.
 */
public class Rygel.RootDeviceFactory {
    public GUPnP.Context context;

    private Configuration config;

    private string desc_dir;

    public RootDeviceFactory (GUPnP.Context context) throws GLib.Error {
        this.config = MetaConfig.get_default ();
        this.context = context;

        /* We store the modified descriptions in the user's config dir */
        this.desc_dir = Path.build_filename (Environment.get_user_config_dir (),
                                             "Rygel");
        this.ensure_dir_exists (this.desc_dir);
    }

    public RootDevice create (Plugin plugin) throws GLib.Error {
        string modified_desc = plugin.name + ".xml";
        string desc_path = Path.build_filename (this.desc_dir,
                                                modified_desc);

        /* Create the description xml */
        var doc = this.create_desc (plugin, desc_path);

        return new RootDevice (this.context,
                               plugin,
                               doc,
                               desc_path,
                               BuildConfig.DATA_DIR);
    }

    private XMLDoc create_desc (Plugin plugin,
                                string desc_path) throws GLib.Error {
        string path;

        if (this.check_path_exist (desc_path)) {
            path = desc_path;
        } else {
            /* Use the template */
            path = plugin.desc_path;
        }

        var doc = new XMLDoc.from_path (path);

        /* Modify description to include Plugin-specific stuff */
        this.prepare_desc_for_plugin (doc, plugin);

        save_modified_desc (doc, desc_path);

        return doc;
    }

    private void prepare_desc_for_plugin (XMLDoc doc, Plugin plugin) {
        Xml.Node *device_element;

        device_element = Utils.get_xml_element ((Xml.Node *) doc.doc,
                                                "root",
                                                "device",
                                                null);
        if (device_element == null) {
            warning ("Element /root/device not found.");

            return;
        }

        /* First, set the Friendly name and UDN */
        this.set_friendly_name_and_udn (device_element,
                                        plugin.name,
                                        plugin.title);

        /* Then list each icon */
        this.add_icons_to_desc (device_element, plugin);

        /* Then list each service */
        this.add_services_to_desc (device_element, plugin);
    }

    /**
     * Fills the description doc @doc with a friendly name, and UDN from gconf.
     * If these keys are not present in gconf, they are set with default values.
     */
    private void set_friendly_name_and_udn (Xml.Node *device_element,
                                            string    plugin_name,
                                            string    plugin_title) {
        /* friendlyName */
        Xml.Node *element = Utils.get_xml_element (device_element,
                                                   "friendlyName",
                                                   null);
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        string title;
        try {
            title = this.config.get_title (plugin_name);
        } catch (GLib.Error err) {
            title = plugin_title;
        }

        title = title.replace ("@REALNAME@", Environment.get_real_name ());
        title = title.replace ("@USERNAME@", Environment.get_user_name ());
        title = title.replace ("@HOSTNAME@", Environment.get_host_name ());

        element->set_content (title);

        /* UDN */
        element = Utils.get_xml_element (device_element, "UDN");
        if (element == null) {
            warning ("Element /root/device/UDN not found.");

            return;
        }

        var udn = element->get_content ();
        if (udn == null || udn == "") {
            udn = Utils.generate_random_udn ();

            element->set_content (udn);
        }
    }

    private void add_services_to_desc (Xml.Node *device_element,
                                       Plugin    plugin) {
        Xml.Node *service_list_node = Utils.get_xml_element (device_element,
                                                             "serviceList",
                                                             null);
        if (service_list_node == null) {
            warning ("Element /root/device/serviceList not found.");

            return;
        }

        // Clear the existing service list first
        service_list_node->set_content ("");

        foreach (ResourceInfo resource_info in plugin.resource_infos) {
            // FIXME: We only support plugable services for now
            if (resource_info.type.is_a (typeof (Service))) {
                    this.add_service_to_desc (service_list_node,
                                              plugin.name,
                                              resource_info);
            }
        }
    }

    private void add_service_to_desc (Xml.Node    *service_list_node,
                                      string       plugin_name,
                                      ResourceInfo resource_info) {
        // Now create the service node
        Xml.Node *service_node = service_list_node->new_child (null, "service");

        service_node->new_child (null, "serviceType", resource_info.upnp_type);
        service_node->new_child (null, "serviceId", resource_info.upnp_id);

        /* Now the relative (to base URL) URLs*/
        string url = resource_info.description_path;
        service_node->new_child (null, "SCPDURL", url);

        url = plugin_name + "/" + resource_info.type.name () + "/Event";
        service_node->new_child (null, "eventSubURL", url);

        url = plugin_name + "/" + resource_info.type.name () + "/Control";
        service_node->new_child (null, "controlURL", url);
    }

    private void add_icons_to_desc (Xml.Node *device_element,
                                    Plugin    plugin) {
        if (plugin.icon_infos == null || plugin.icon_infos.size == 0) {
            debug ("No icon provided by %s.", plugin.name);

            return;
        }

        Xml.Node *icon_list_node = Utils.get_xml_element (device_element,
                                                          "iconList",
                                                          null);
        if (icon_list_node == null) {
            icon_list_node = device_element->new_child (null, "iconList", null);
        } else {
            // Clear the existing icon list first
            icon_list_node->set_content ("");
        }

        foreach (IconInfo icon_info in plugin.icon_infos) {
            add_icon_to_desc (icon_list_node, icon_info, plugin);
        }
    }

    private void add_icon_to_desc (Xml.Node *icon_list_node,
                                   IconInfo  icon_info,
                                   Plugin    plugin) {
        // Create the service node
        Xml.Node *icon_node = icon_list_node->new_child (null, "icon");

        string width = icon_info.width.to_string ();
        string height = icon_info.height.to_string ();
        string depth = icon_info.depth.to_string ();

        icon_node->new_child (null, "mimetype", icon_info.mime_type);
        icon_node->new_child (null, "width", width);
        icon_node->new_child (null, "height", height);
        icon_node->new_child (null, "depth", depth);

        var uri = icon_info.uri;

        if (uri.has_prefix ("file://")) {
            // /PLUGIN_NAME-WIDTHxHEIGHTxDEPTH.png
            var remote_path = "/" + plugin.name + "-" +
                              width + "x" +
                              height + "x" +
                              depth + ".png";
            var local_path = uri.offset (7);

            this.context.host_path (local_path, remote_path);
            icon_node->new_child (null, "url", remote_path);
        } else {
            uri = uri.replace ("@ADDRESS@", this.context.host_ip);
            icon_node->new_child (null, "url", uri);
        }
    }

    private void save_modified_desc (XMLDoc doc,
                                     string desc_path) throws GLib.Error {
        FileStream f = FileStream.open (desc_path, "w+");
        int res = -1;

        if (f != null)
            res = doc.doc.dump (f);

        if (f == null || res == -1) {
            string message = "Failed to write modified description" +
                             " to %s.\n".printf (desc_path);

            throw new IOError.FAILED (message);
        }
    }

    private bool check_path_exist (string path) {
        var file = File.new_for_path (path);

        return file.query_exists (null);
    }

    private void ensure_dir_exists (string dir_path) throws Error {
        if (!check_path_exist (dir_path)) {
            var file = File.new_for_path (dir_path);

            file.make_directory (null);
        }
    }
}

