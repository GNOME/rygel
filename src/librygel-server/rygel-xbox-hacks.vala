/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

/*
 * The XBox360 is a very early UPnP device and does not follow the final UPnP MediaServer:1 specification.
 * On top of this, it also requires an additional security device to be present. Fortunately, a dummy
 * implementation is sufficient. See rygel-media-reciver-registrar.vala for its implementation.
 *
 * Hacks implemented here:
 *  - MediaServer and ContentDirectory have to be version :1
 *  - modelName in the device description _must_ be "Windows Media Player Sharing"
 *  - modelNumber _must_ be set to 11 or 12
 *  - friendlyName in the device description _must_ contain ":"
 *  - Browse requests need to understand the parameter ContainerID instead of ObjectID
 *  - Music playback requires implementation of the optional ContentDirectory.Search method
 *  - Containers need to be of the class object.container.storageFolder (we just use this throughout the server)
 *  - Images need to have the class object.item.imageItem.photo (as above)
 *  - AVI files are accepted with content-type video/avi
 *  - MPEG files are not shown at all if their content-type is video/mpeg. We use an invalid content type to force transcoding.
 *  - Thumbnails will be downloaded using the file URI + "?albumArt=true"
 *
 *  Furthermore, for music playback the XBox360 uses hard-coded container ids
 *      Id | Meaning   | used in |
 *      -- | --------- | ------- |
 *      14 | Music     | Browse  |
 *      15 | Videos    | Browse  |
 *      16 | Pictures  | Browse  |
 *       4 | All Music | Search  |
 *       5 | Genre     | Search  |
 *       6 | Artist    | Search  |
 *       7 | Album     | Search  |
 *       F | Playlists | Search  |
 *
 */

internal class Rygel.XBoxHacks : ClientHacks {
    private const string AGENT = ".*Xbox.*";
    private const string DMS = "urn:schemas-upnp-org:device:MediaServer";
    private const string DMS_V1 = DMS + ":1";
    private const string FRIENDLY_NAME_POSTFIX = ":";
    private const string MODEL_NAME = "Windows Media Player Sharing";
    private const string MODEL_VERSION = "11";
    private const string CONTAINER_ID = "ContainerID";

    public XBoxHacks (ServerMessage? message = null) throws ClientHacksError {
        base (AGENT, message);

        this.object_id = CONTAINER_ID;
        // Rewrite request URI to be a thumbnail request if it matches those
        // weird XBox thumbnail requests
        if (message == null) {
            return;
        }

        var query = message.get_uri ().get_query ();
        if (query == null) {
            return;
        }

        var iter = GLib.UriParamsIter (query);
        string param;
        string val;
        bool rewrite = false;
        try {
            while (iter.next (out param, out val)) {
                if (param == "albumArt") {
                    if (!bool.parse (val)) {
                        return;
                    } else {
                        rewrite = true;

                        break;
                    }
                }
            }
        } catch (Error error) {
            return;
        }

        if (!rewrite) {
            return;
        }

        var path = message.get_uri ().get_path ();
        var particles = path.split ("/")[0:4];
        particles += "th";
        particles += "0";

        message.set_redirect (Soup.Status.MOVED_PERMANENTLY, string.joinv ("/", particles));
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

        var server_path = "/" + device.get_description_document_name ();
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

        foreach (var resource in object.get_resource_list ()) {
            if (resource.mime_type == "video/x-msvideo") {
                resource.mime_type = "video/avi";
            } else if (resource.mime_type == "video/mpeg") {
                // Force transcoding for MPEG files
                resource.mime_type = "invalid/content";
            }
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
                                         string              sort_criteria,
                                         Cancellable?        cancellable,
                                         out uint            total_matches)
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
                                              sort_criteria,
                                              cancellable,
                                              out total_matches);
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
