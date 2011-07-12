/*
 * Copyright (C) 2010 Nokia Corporation.
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

using Soup;
using GUPnP;

internal errordomain Rygel.XBoxHacksError {
    NA
}

internal class Rygel.XBoxHacks : GLib.Object {
    private static string AGENT = ".*Xbox.*|.*Allegro-Software-WebClient.*";
    private static string DMS = "urn:schemas-upnp-org:device:MediaServer";
    private static string DMS_V1 = DMS + ":1";
    private static string FRIENDLY_NAME_POSTFIX = ":";
    private static string MODEL_NAME = "Windows Media Player Sharing";
    private static string MODEL_VERSION = "11";
    private static string CONTAINER_ID = "ContainerID";
    private static string OBJECT_ID = "ObjectID";

    public unowned string object_id { get; private set; }

    public XBoxHacks.for_action (ServiceAction action) throws XBoxHacksError {
        unowned MessageHeaders headers = action.get_message ().request_headers;
        this.check_headers (headers);
    }

    public XBoxHacks.for_headers (MessageHeaders headers)
                                  throws XBoxHacksError {
        this.check_headers (headers);
    }

    private void check_headers (MessageHeaders headers) throws XBoxHacksError {
        var agent = headers.get_one ("User-Agent");
        if (agent == null ||
            !(agent.contains ("Xbox")) &&
            !(agent.contains ("Allegro-Software-WebClient"))) {
            throw new XBoxHacksError.NA (_("Not Applicable"));
        }

        if (agent.contains ("Xbox")) {
            this.object_id = CONTAINER_ID;
        } else {
            this.object_id = OBJECT_ID;
        }
    }

    public bool is_album_art_request (Soup.Message message) {
        unowned string query = message.get_uri ().query;

        if (query == null) {
            return false;
        }

        var params = Soup.Form.decode (query);
        var album_art = params.lookup ("albumArt");

        return (album_art != null) && bool.parse (album_art);
    }

    public void apply_on_device (RootDevice device,
                                 string     template_path) throws Error {
        if (!device.get_device_type ().has_prefix (DMS)) {
            return;
        }

        var doc = new XMLDoc.from_path (template_path);
        this.modify_dms_desc (doc.doc);

        var desc_path = template_path.replace (".xml", "-xbox.xml");
        this.save_modified_desc (doc, desc_path);

        var regex = new Regex (AGENT, RegexCompileFlags.CASELESS, 0);
        var server_path = "/" + device.get_relative_location ();
        device.context.host_path_for_agent (desc_path, server_path, regex);
    }

    public void translate_container_id (MediaQueryAction action,
                                        ref string       container_id) {
        if (action is Search &&
            (container_id == "1" ||
             container_id == "4" ||
             container_id == "5" ||
             container_id == "6" ||
             container_id == "7" ||
             container_id == "F") ||
            (action is Browse &&
             container_id == "15" ||
             container_id == "14" ||
             container_id == "16")) {
            container_id = "0";
        }
    }

    public void apply (MediaItem item) {
        if (item.mime_type == "video/x-msvideo") {
            item.mime_type = "video/avi";
        } else if (item.mime_type == "video/mpeg") {
            // Force transcoding for MPEG files
            item.mime_type = "invalid/content";
        }
    }

    public async MediaObjects? search (SearchableContainer container,
                                       SearchExpression?   expression,
                                       uint                offset,
                                       uint                max_count,
                                       out uint            total_matches,
                                       Cancellable?        cancellable)
                                       throws Error {
        var results = yield container.search (expression,
                                              offset,
                                              max_count,
                                              out total_matches,
                                              cancellable);
        if (total_matches == 0 && expression is RelationalExpression) {
            var rel_expression = expression as RelationalExpression;

            if (likely (rel_expression.operand1 != null) &&
                rel_expression.operand1 == "upnp:class") {
                total_matches = results.size;
            }
        }

        return results;
    }

    private void modify_dms_desc (Xml.Doc doc) {
        Xml.Node *element = XMLUtils.get_element ((Xml.Node *) doc,
                                                  "root",
                                                  "device",
                                                  "deviceType");
        assert (element != null);
        element->set_content (DMS_V1);

        element = XMLUtils.get_element ((Xml.Node *) doc,
                                        "root",
                                        "device",
                                        "modelName");
        assert (element != null);
        element->set_content (MODEL_NAME);

        element = XMLUtils.get_element ((Xml.Node *) doc,
                                        "root",
                                        "device",
                                        "modelNumber");

        assert (element != null);
        element->set_content (MODEL_VERSION);

        element = XMLUtils.get_element ((Xml.Node *) doc,
                                        "root",
                                        "device",
                                        "friendlyName");
        assert (element != null);
        element->add_content (FRIENDLY_NAME_POSTFIX);

        this.modify_service_list (doc);
    }

    private void modify_service_list (Xml.Node *doc_node) {
        Xml.Node *element = XMLUtils.get_element (doc_node,
                                                  "root",
                                                  "device",
                                                  "serviceList");
        assert (element != null && element->children != null);

        for (var service_node = element->children;
             service_node != null;
             service_node = service_node->next) {
            for (var type_node = service_node->children;
                 type_node != null;
                 type_node = type_node->next) {
                if (type_node->name == "serviceType") {
                    switch (type_node->get_content ()) {
                        case ContentDirectory.UPNP_TYPE:
                            type_node->set_content
                                        (ContentDirectory.UPNP_TYPE_V1);
                            break;
                        case MediaReceiverRegistrar.UPNP_TYPE:
                            type_node->set_content
                                        (MediaReceiverRegistrar.COMPAT_TYPE);
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }

    private void save_modified_desc (XMLDoc doc,
                                     string desc_path) throws GLib.Error {
        FileStream f = FileStream.open (desc_path, "w+");
        int res = -1;

        if (f != null)
            res = doc.doc.dump (f);

        if (f == null || res == -1) {
            var message = _("Failed to write modified description to %s.");

            throw new IOError.FAILED (message, desc_path);
        }
    }
}
