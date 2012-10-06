/*
 * Copyright (C) 2011 Nokia Corporation.
 * Copyright (C) 2012 Jens Georg.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Jens Georg <mail@jensge.org>
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
    private const string[] AGENTS = { "Allegro-Software-WebClient",
                                      "SEC HHP",
                                      "SEC_HHP",
                                      "Mediabolic-IMHTTP/1.",
                                      "TwoPlayer",
                                      "Reciva" };

    private const string DMS = "urn:schemas-upnp-org:device:MediaServer";
    private const string DMS_V1 = DMS + ":1";
    private const string MATCHING_PATTERN = ".*%s.*";

    private static string agent_pattern;

    public string description_path;

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
        var raw_agents = AGENTS;
        try {
            raw_agents = config.get_string_list ("general",
                                                 "force-downgrade-for").
                                                 to_array ();
        } catch (Error error) {}

        var agents = new string[0];
        foreach (var agent in raw_agents) {
            agents += MATCHING_PATTERN.printf
                                    (Regex.escape_string (agent));
        }

        if (agents.length > 0) {
            agent_pattern = string.joinv ("|", agents);
        } else {
            agent_pattern = "";
        }

        debug ("V1 downgrade will be applied for devices matching %s",
               agent_pattern);

        return agent_pattern;
    }

    public V1Hacks () throws ClientHacksError {
        base (generate_agent_pattern (), null);
    }

    public void apply_on_device (RootDevice device,
                                 string?    template_path) throws Error {
        if (!device.get_device_type ().has_prefix (DMS)) {
            return;
        }

        if (template_path == null) {
            return;
        }

        var description_file = new DescriptionFile (template_path);
        description_file.set_device_type (DMS_V1);
        description_file.modify_service_type (ContentDirectory.UPNP_TYPE,
                                              ContentDirectory.UPNP_TYPE_V1);

        this.description_path = template_path.replace (".xml", "-v1.xml");
        description_file.save (this.description_path);

        var server_path = "/" + device.get_relative_location ();
        if (this.agent_regex.get_pattern () != "") {
            device.context.host_path_for_agent (this.description_path,
                                                server_path,
                                                this.agent_regex);
        }
    }
}
