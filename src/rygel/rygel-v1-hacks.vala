/*
 * Copyright (C) 2011 Nokia Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * Various devices that need a downgrade to MediaServer:1 and
 * ContentDirectory:1 because they ignore that higher versions are
 * required to be backwards-compatible.
 */
internal class Rygel.V1Hacks : ClientHacks {
    private const string DEFAULT_AGENT = ".*Allegro-Software-WebClient.*|" +
                                         ".*SEC_HHP_Galaxy S/1\\.0.*";
    private const string DMS = "urn:schemas-upnp-org:device:MediaServer";
    private const string DMS_V1 = DMS + ":1";
    private const string MATCHING_PATTERN = ".*%s.*";

    private static string agent_pattern;

    /**
     * Read the user-agent snippets from the config file and generate the
     * regular expression string for matching.
     *
     * Returns: A regular expression pattern matching any of the configured
     *          user-agents.
     */
    private static string generate_agent_pattern () {
        if (likely (agent_pattern != null)) {
            return agent_pattern;
        }

        var config = MetaConfig.get_default ();
        agent_pattern = DEFAULT_AGENT;
        try {
            var raw_agents = config.get_string_list ("general",
                                                     "force-downgrade-for");
            var agents = new string[0];
            foreach (var agent in raw_agents) {
                agents += MATCHING_PATTERN.printf
                                        (Regex.escape_string (agent));
            }

            if (agents.length > 0) {
                agent_pattern = string.joinv ("|", agents);
            }
        } catch (Error error) {}

        debug ("V1 downgrade will be applied for devices matching %s",
               agent_pattern);

        return agent_pattern;
    }

    public V1Hacks () throws ClientHacksError {
        base (generate_agent_pattern (), null);
    }

    public void apply_on_device (RootDevice device,
                                 string     template_path) throws Error {
        if (!device.get_device_type ().has_prefix (DMS)) {
            return;
        }

        var doc = new XMLDoc.from_path (template_path);
        this.modify_dms_desc (doc.doc);

        var desc_path = template_path.replace (".xml", "-v1.xml");
        this.save_modified_desc (doc, desc_path);

        var server_path = "/" + device.get_relative_location ();
        device.context.host_path_for_agent (desc_path,
                                            server_path,
                                            this.agent_regex);
    }

    private void modify_dms_desc (Xml.Doc doc) {
        Xml.Node *element = XMLUtils.get_element ((Xml.Node *) doc,
                                                  "root",
                                                  "device",
                                                  "deviceType");
        assert (element != null);
        element->set_content (DMS_V1);

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
