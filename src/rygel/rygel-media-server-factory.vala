/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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
using Rygel;

public errordomain MediaServerFactoryError {
    XML_PARSE
}

/**
 * Factory for MediaServer objects. Give it a plugin and it will create a
 * MediaServer device for that.
 */
public class Rygel.MediaServerFactory {
    public static const string DESC_DOC = "xml/description.xml";
    public static const string XBOX_DESC_DOC = "xml/description-xbox360.xml";
    public static const string DESC_PREFIX = "Rygel";

    private Configuration config;
    private GUPnP.Context context;

    public MediaServerFactory () throws GLib.Error {
        this.config = new Configuration ();

        /* Set up GUPnP context */
        this.context = create_upnp_context ();
    }

    public MediaServer create_media_server (Plugin plugin) throws GLib.Error {
        string modified_desc = DESC_PREFIX + "-" + plugin.name + ".xml";

        /* We store a modified description.xml in the user's config dir */
        string desc_path = Path.build_filename
                                    (Environment.get_user_config_dir (),
                                     modified_desc);

        /* Create the description xml */
        Xml.Doc *doc = this.create_desc (plugin, desc_path);

        /* Host our modified file */
        this.context.host_path (desc_path, "/" + modified_desc);

        return new MediaServer (this.context,
                                plugin,
                                doc,
                                modified_desc);
    }

    private Xml.Doc * create_desc (Plugin plugin,
                                   string desc_path) throws GLib.Error {
        string orig_desc_path;

        if (this.config.enable_xbox)
            /* Use Xbox 360 specific description */
            orig_desc_path = Path.build_filename (BuildConfig.DATA_DIR,
                                                  XBOX_DESC_DOC);
        else
            orig_desc_path = Path.build_filename (BuildConfig.DATA_DIR,
                                                  DESC_DOC);

        Xml.Doc *doc = Xml.Parser.parse_file (orig_desc_path);
        if (doc == null) {
            string message = "Failed to parse %s".printf (orig_desc_path);

            throw new MediaServerFactoryError.XML_PARSE (message);
        }

        /* Modify description to include Plugin-specific stuff */
        this.prepare_desc_for_plugin (doc, plugin);

        if (this.config.enable_xbox)
            /* Put/Set XboX specific stuff to description */
            add_xbox_specifics (doc);

        save_modified_desc (doc, desc_path);

        return doc;
    }

    private GUPnP.Context create_upnp_context () throws GLib.Error {
        GUPnP.Context context = new GUPnP.Context (null,
                                                   this.config.host_ip,
                                                   this.config.port);

        /* Host UPnP dir */
        context.host_path (BuildConfig.DATA_DIR, "");

        return context;
    }

    private void add_xbox_specifics (Xml.Doc doc) {
        Xml.Node *element;

        element = Utils.get_xml_element ((Xml.Node *) doc,
                                         "root",
                                         "device",
                                         "friendlyName");
        /* friendlyName */
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        element->add_content (": 1 : Windows Media Connect");
    }

    private void prepare_desc_for_plugin (Xml.Doc doc, Plugin plugin) {
        Xml.Node *device_element;

        device_element = Utils.get_xml_element ((Xml.Node *) doc,
                                                "root",
                                                "device",
                                                null);
        if (device_element == null) {
            warning ("Element /root/device not found.");

            return;
        }

        /* First, set the Friendly name and UDN */
        this.set_friendly_name_and_udn (device_element, plugin.name);

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
                                            string    plugin_name) {
        /* friendlyName */
        Xml.Node *element = Utils.get_xml_element (device_element,
                                                   "friendlyName",
                                                   null);
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        element->set_content (this.config.get_title (plugin_name));

        /* UDN */
        element = Utils.get_xml_element (device_element, "UDN");
        if (element == null) {
            warning ("Element /root/device/UDN not found.");

            return;
        }

        element->set_content (this.config.get_udn (plugin_name));
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
        // Create the service node
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

        Xml.Node *icon_list_node = device_element->new_child (null,
                                                              "iconList",
                                                              null);
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

        icon_node->new_child (null, "mimetype", icon_info.mimetype);
        icon_node->new_child (null, "width", width);
        icon_node->new_child (null, "height", height);
        icon_node->new_child (null, "depth", depth);

        // PLUGIN_NAME-WIDTHxHEIGHTxDEPTH.png
        string url = plugin.name + "-" +
                     width + "x" + height + "x" + depth + ".png";

        this.context.host_path (icon_info.path, "/" + url);
        icon_node->new_child (null, "url", url);
    }

    private void save_modified_desc (Xml.Doc *doc,
                                     string   desc_path) throws GLib.Error {
        FileStream f = FileStream.open (desc_path, "w+");
        int res = -1;

        if (f != null)
            res = Xml.Doc.dump (f, doc);

        if (f == null || res == -1) {
            string message = "Failed to write modified description" +
                             " to %s.\n".printf (desc_path);

            delete doc;

            throw new IOError.FAILED (message);
        }
    }
}

