/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

// Represents a search expression that consists of two strings joined by a
// relational operator.
public class Rygel.RelationalExpression :
             Rygel.SearchExpression<SearchCriteriaOp,string,string> {
    internal const string CAPS = "@id,@parentID,@refID,upnp:class," +
                                 "dc:title,dc:creator,upnp:createClass," +
                                 "res,res@protocolInfo";

    public override bool satisfied_by (MediaObject media_object) {
        switch (this.operand1) {
        case "@id":
            return this.compare_string (media_object.id);
        case "@parentID":
            return this.compare_string (media_object.parent.id);
        case "@refID":
            return false; // We don't have refIDs yet
        case "upnp:class":
            return this.compare_string (media_object.upnp_class);
        case "dc:title":
            return this.compare_string (media_object.title);
        case "upnp:createClass":
            if (!(media_object is MediaContainer)) {
                return false;
            }

            var container = media_object as MediaContainer;
            return this.compare_create_class (container);
        case "dc:creator":
            if (!(media_object is MediaItem)) {
                return false;
            }

            var item = media_object as MediaItem;
            return this.compare_string (item.author);
        default:
            if (this.operand1.has_prefix ("res")) {
                return this.compare_resource (media_object);
            } else {
                return false;
            }
        }
    }

    public override string to_string () {
        return "%s %d %s".printf (this.operand1, this.op, this.operand2);
    }

    private bool compare_create_class (MediaContainer container) {
        var ret = false;

        foreach (var create_class in container.create_classes) {
            if (this.compare_string (create_class)) {
                ret = true;

                break;
            }
        }

        return ret;
    }

    private bool compare_resource (MediaObject media_object) {
        bool ret = false;

        foreach (var uri in media_object.uris) {
            if (this.operand1 == "res" && this.compare_string (uri)) {
                ret = true;
                break;
            } else if (this.operand1 == "res@protocolInfo") {
                // FIXME: Implement
            }
        }

        return ret;
    }

    public bool compare_string (string? str) {
        switch (this.op) {
        case SearchCriteriaOp.EXISTS:
            if (this.operand2 == "true") {
                return str != null;
            } else {
                return str == null;
            }
        case SearchCriteriaOp.EQ:
            return this.operand2 == str;
        case SearchCriteriaOp.CONTAINS:
            return str.contains (this.operand2);
        case SearchCriteriaOp.DERIVED_FROM:
            return str.has_prefix (this.operand2);
        default:
            return false;
        }
    }
}
