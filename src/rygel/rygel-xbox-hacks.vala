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

internal class Rygel.XBoxHacks : ClientHacks {
    private const string AGENT = ".*Xbox.*";
    private const string DMS = "urn:schemas-upnp-org:device:MediaServer";
    private const string DMS_V1 = DMS + ":1";
    private const string FRIENDLY_NAME_POSTFIX = ":";
    private const string MODEL_NAME = "Windows Media Player Sharing";
    private const string MODEL_VERSION = "11";
    private const string CONTAINER_ID = "ContainerID";

    public XBoxHacks (Message? message = null) throws ClientHacksError {
        base (AGENT, message);

        this.object_id = CONTAINER_ID;
        // Rewrite request URI to be a thumbnail request if it matches those
        // weird XBox thumbnail requests
        if (message == null) {
            return;
        }

        unowned Soup.URI uri = message.get_uri ();
        unowned string query = uri.query;
        if (query == null) {
            return;
        }
        var params = Soup.Form.decode (query);
        var album_art = params.lookup ("albumArt");

        if ((album_art == null) || !bool.parse (album_art)) {
            return;
        }

        uri.set_path (uri.get_path () + "/th/0");
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
        description_file.set_model_name (MODEL_NAME);
        description_file.set_model_number (MODEL_VERSION);

        var friendly_name = description_file.get_friendly_name ();
        description_file.set_friendly_name (friendly_name +
                                            FRIENDLY_NAME_POSTFIX);

        description_file.modify_service_type
                                        (MediaReceiverRegistrar.UPNP_TYPE,
                                         MediaReceiverRegistrar.COMPAT_TYPE);

        var desc_path = template_path.replace ("v1.xml", "xbox.xml");
        description_file.save (desc_path);

        var server_path = "/" + device.get_relative_location ();
        device.context.host_path_for_agent (desc_path,
                                            server_path,
                                            this.agent_regex);
    }

    public override void translate_container_id
                                        (MediaQueryAction action,
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

    public override void apply (MediaItem item) {
        if (item.mime_type == "video/x-msvideo") {
            item.mime_type = "video/avi";
        } else if (item.mime_type == "video/mpeg") {
            // Force transcoding for MPEG files
            item.mime_type = "invalid/content";
        }
    }

    public override void filter_sort_criteria (ref string sort_criteria) {
        sort_criteria = sort_criteria.replace ("+microsoft:sourceURL", "");
        sort_criteria = sort_criteria.replace (",,", ",");
        if (sort_criteria.has_prefix (",")) {
            sort_criteria = sort_criteria.slice (1, sort_criteria.length);
        }
    }

    public override async MediaObjects? search
                                        (SearchableContainer container,
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
}
