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

        var path = uri.get_path ();
        var particles = path.split ("/")[0:4];
        particles += "th";
        particles += "0";

        uri.set_path (string.joinv("/", particles));
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

    public override void apply (MediaObject object) {
        if (object is MediaContainer) {
            if (object.upnp_class == MediaContainer.UPNP_CLASS) {
                object.upnp_class = MediaContainer.STORAGE_FOLDER;
            }

            return;
        }

        if (! (object is MediaFileItem)) {
            return;
        }

        var item = object as MediaFileItem;

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
                                         string              sort_criteria,
                                         Cancellable?        cancellable)
                                         throws Error {
        var set_total_matches = false;
        var modified_expression = expression;

        // check if the XBox is trying to get all the songs.
        // If so, rewrite the search to exclude @refID items, otherwise they
        // songs will show up multiple times in the listing.
        if (expression is RelationalExpression) {
            var rel_expression = expression as RelationalExpression;

            if (likely (rel_expression.operand1 != null) &&
                rel_expression.operand1 == "upnp:class") {
                set_total_matches = true;

                if (rel_expression.op == SearchCriteriaOp.DERIVED_FROM &&
                    rel_expression.operand2 != null &&
                    rel_expression.operand2 == AudioItem.UPNP_CLASS &&
                    container.id == "0") {
                    modified_expression = this.rewrite_search_expression
                                        (expression);
                }
            }
        }

        var results = yield container.search (modified_expression,
                                              offset,
                                              max_count,
                                              out total_matches,
                                              sort_criteria,
                                              cancellable);
        if (total_matches == 0 && set_total_matches) {
            total_matches = results.size;
        }

        return results;
    }

    private SearchExpression rewrite_search_expression
                                        (SearchExpression expression) {
        var ref_id_expression = new RelationalExpression ();
        ref_id_expression.operand1 = "@refID";
        ref_id_expression.op = SearchCriteriaOp.EXISTS;
        ref_id_expression.operand2 = "false";

        var new_expression = new LogicalExpression ();
        new_expression.operand1 = expression;
        new_expression.op = LogicalOperator.AND;
        new_expression.operand2 = ref_id_expression;

        return new_expression;
    }
}
