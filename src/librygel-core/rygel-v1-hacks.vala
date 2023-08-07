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

using Soup;
using GUPnP;

/**
 * Various devices that need a downgrade to MediaServer:1 and
 * ContentDirectory:1 because they ignore that higher versions are
 * required to be backwards-compatible.
 */
// FIXME: internal
public class Rygel.V1Hacks : Object {
    private const string[] AGENTS = { "Allegro-Software-WebClient",
                                      "SEC HHP",
                                      "SEC_HHP",
                                      "Mediabolic-IMHTTP/1.",
                                      "TwoPlayer",
                                      "Reciva",
                                      "FDSSDP",
                                      "Portable SDK for UPnP devices",
                                      "Darwin"};

    private string _device_type;
    public string device_type {
        construct set {
            this._device_type = value;
            this.device_type_v1 = value + ":1";
        }
        get { return this._device_type; }
    }
    private string device_type_v1;

    public string[] service_types { construct; get; }

    private const string MATCHING_PATTERN = ".*%s.*";
    private const string SERVICE_TYPE_PATTERN = ":[0-9]+$";

    public string description_path;

    private static AgentMatcher agent_matcher;
    private Regex service_type_regex;

    public V1Hacks (string device_type,
                    string[] service_types) {
        Object (device_type : device_type,
                service_types : service_types);
    }

    public override void constructed () {
        base.constructed ();

        if (V1Hacks.agent_matcher == null) {
            var defaults = new Gee.ArrayList<string>.wrap (AGENTS, (Gee.EqualDataFunc<string>?)str_equal);
            var config = MetaConfig.get_default ();
            var agents = config.get_string_list_with_default ("general", "force-downgrade-for", defaults);
            agent_matcher = new AgentMatcher("V1 hacks", agents);
        }

        try {
            this.service_type_regex = new Regex (SERVICE_TYPE_PATTERN);
        } catch (Error error) { assert_not_reached (); }
    }

    public void apply_on_device (RootDevice device,
                                 string?    template_path) throws Error {
        if (!device.get_device_type ().has_prefix (device_type)) {
            return;
        }

        if (template_path == null) {
            return;
        }

        var description_file = new DescriptionFile (template_path);
        description_file.set_device_type (device_type_v1);

        foreach (var service_type in service_types) {
            var service_type_v1 = this.service_type_regex.replace_literal
                                        (service_type, -1, 0, ":1");
            description_file.modify_service_type (service_type, service_type_v1);
        }

        this.description_path = template_path.replace (".xml", "-v1.xml");
        description_file.save (this.description_path);

        var server_path = "/" + device.get_description_document_name ();
        if (V1Hacks.agent_matcher.agent_regex.get_pattern () != "") {
            device.context.host_path_for_agent (this.description_path,
                                                server_path,
                                                V1Hacks.agent_matcher.agent_regex);
        }
    }
}
