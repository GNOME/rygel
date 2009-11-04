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

public enum Rygel.LogicalOperator {
    AND,
    OR
}

/**
 * Represents a SearchExpression tree.
 */
public abstract class Rygel.SearchExpression<G,H,I> {
    public G op; // Operator

    public H operand1;
    public I operand2;

    public abstract async bool satisfied_by (MediaObject media_object);

    public abstract string to_string ();
}

public class Rygel.AtomicExpression :
             Rygel.SearchExpression<SearchCriteriaOp,string,string> {
    public override async bool satisfied_by (MediaObject media_object) {
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

    private bool compare_string (string? str) {
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
            return this.operand2.contains (str);
        case SearchCriteriaOp.DERIVED_FROM:
            return this.operand2.has_prefix (str);
        default:
            return false;
        }
    }
}

public class Rygel.LogicalExpression :
             Rygel.SearchExpression<LogicalOperator,
                                    SearchExpression,
                                    SearchExpression> {
    public override async bool satisfied_by (MediaObject media_object) {
        return true;
    }

    public override string to_string () {
        return "(%s %d %s)".printf (this.operand1.to_string (),
                                    this.op,
                                    this.operand2.to_string ());
    }
}
