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

public errordomain RootDeviceFactoryError {
    XML_PARSE,
}

/**
 * This is a factory to create #RygelRootDevice objects for
 * a given UPnP context.
 *
 * Call rygel_root_device_factory_create() with a plugin
 * to create a root device for the plugin.
 */
public class Rygel.RootDeviceFactory {
    public GUPnP.Context context {get; private set;}

    private Configuration config;

    private string desc_dir;

    public RootDeviceFactory (GUPnP.Context context) throws GLib.Error {
        this.config = MetaConfig.get_default ();
        this.context = context;

        /* We store the modified descriptions in the user's config dir */
        var config_dir = Environment.get_user_config_dir ();
        this.ensure_dir_exists (config_dir);
        this.desc_dir = Path.build_filename (config_dir,
                                             Environment.get_application_name ());
        this.ensure_dir_exists (this.desc_dir);
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
        this.prepare_desc_for_plugin (doc, plugin);

        var file = new DescriptionFile.from_xml_document (doc);
        file.set_dlna_caps (plugin.capabilities);
        file.save (desc_path);

        return doc;
    }

    private void prepare_desc_for_plugin (XMLDoc doc, Plugin plugin) {
        Xml.Node *device_element;

        device_element = XMLUtils.get_element ((Xml.Node *) doc.doc,
                                               "root",
                                               "device",
                                               null);
        if (device_element == null) {
            warning (_("XML node '%s' not found."), "/root/device");

            return;
        }

        /* First, set the Friendly name and UDN */
        this.set_friendly_name_and_udn (device_element,
                                        plugin.name,
                                        plugin.title);

        if (plugin.description != null) {
            this.set_description (device_element, plugin.description);
        }

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
        Xml.Node *element = XMLUtils.get_element (device_element,
                                                  "friendlyName",
                                                  null);
        if (element == null) {
            warning (_("XML node '%s' not found."),
                       "/root/device/friendlyName");

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
        element = XMLUtils.get_element (device_element, "UDN");
        if (element == null) {
            warning (_("XML node '%s' not found."), "/root/device/UDN");

            return;
        }

        var udn = element->get_content ();
        if (udn == null || udn == "") {
            udn = this.generate_random_udn ();

            element->set_content (udn);
        }
    }

    private void set_description (Xml.Node *device_element,
                                  string    description) {
        Xml.Node *element = XMLUtils.get_element (device_element,
                                                  "modelDescription",
                                                  null);
        if (element == null) {
            device_element->new_child (null, "modelDescription", description);
        }

        element->set_content (description);
    }

    private void add_services_to_desc (Xml.Node *device_element,
                                       Plugin    plugin) {
        Xml.Node *service_list_node = XMLUtils.get_element (device_element,
                                                            "serviceList",
                                                            null);
        if (service_list_node == null) {
            warning (_("XML node '%s' not found."), "/root/device/serviceList");

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
        string url = "/" + resource_info.description_path;
        service_node->new_child (null, "SCPDURL", url);

        url = "/Event/" + plugin_name + "/" + resource_info.type.name ();
        service_node->new_child (null, "eventSubURL", url);

        url = "/Control/" + plugin_name + "/" + resource_info.type.name ();
        service_node->new_child (null, "controlURL", url);
    }

    private void add_icons_to_desc (Xml.Node *device_element,
                                    Plugin    plugin) {
        var icons = plugin.icon_infos;

        if (icons == null || icons.size == 0) {
            debug ("No icon provided by plugin '%s'. Using Rygel logo.",
                   plugin.name);

            icons = plugin.default_icons;
        }

        Xml.Node *icon_list_node = XMLUtils.get_element (device_element,
                                                         "iconList",
                                                         null);
        if (icon_list_node == null) {
            icon_list_node = device_element->new_child (null, "iconList", null);
        } else {
            // Clear the existing icon list first
            icon_list_node->set_content ("");
        }

        foreach (var icon in icons) {
            add_icon_to_desc (icon_list_node, icon, plugin);
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
                              depth + "." + icon_info.file_extension;
            var local_path = uri.substring (7);

            this.context.host_path (local_path, remote_path);
            icon_node->new_child (null, "url", remote_path);
        } else {
            uri = uri.replace ("@ADDRESS@", this.context.host_ip);
            icon_node->new_child (null, "url", uri);
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
        var file = File.new_for_path (dir_path);
        if (!file.query_exists (null)) {
            file.make_directory (null);
        }
    }

    private string generate_random_udn () {
        var udn = new uchar[50];
        var id = new uchar[16];

        /* Generate new UUID */
        UUID.generate (id);
        UUID.unparse (id, udn);

        return "uuid:" + (string) udn;
    }
}
