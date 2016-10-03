/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 * Contact: http://www.cablelabs.com/
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

using Gee;
using Xml;

protected class UIElem : UIListing
{
    private string id = null;
    private string name = null;
    private string description = null;
    private string fork = null;
    private string lifetime = null;

    private ArrayList<IconElem> icons ;
    private ArrayList<ProtocolElem> protocols;

    public UIElem (Xml.Node* node) throws Rygel.RuihServiceError {
        this.icons = new ArrayList<IconElem> ();
        this.protocols = new ArrayList<ProtocolElem> ();

        // invalid XML exception?
        foreach (var child_node in new Rygel.XMLUtils.ChildIterator (node)) {
            if (child_node->type == Xml.ElementType.TEXT_NODE) {
                // ignore text nodes
                continue;
            }

            var node_name = child_node->name;
            switch (node_name) {
            case UIID:
                this.id = child_node->get_content ();
                break;
            case NAME:
                this.name = child_node->get_content ();
                break;
            case DESCRIPTION:
                this.description = child_node->get_content ();
                break;
            case ICONLIST:
                var it = new Rygel.XMLUtils.ChildIterator (child_node);
                foreach (var icon_node in it) {
                    if (icon_node->name == ICON) {
                        this.icons.add (new IconElem (icon_node));
                    }
                }
                break;
            case FORK:
                this.fork = child_node->get_content ();
                break;
            case LIFETIME:
                this.lifetime = child_node->get_content ();
                break;
            case PROTOCOL:
                this.protocols.add (new ProtocolElem (child_node));
                break;
            default:
                var msg = _("Unable to parse UI data — unexpected node: %s");
                throw new Rygel.RuihServiceError.OPERATION_REJECTED
                                        (msg.printf (node_name));
            }
        }
    }

    public override bool match (Gee.ArrayList<ProtocolElem>? protocol_elements,
                               Gee.ArrayList<FilterEntry> filters) {
        if (protocol_elements == null || protocol_elements.size == 0) {
            return true;
        }

        foreach (var proto in protocol_elements) {
            if (proto.match (this.protocols, filters)) {
                return true;
            }
        }

        return false;
    }

    public override string to_ui_listing (Gee.ArrayList<FilterEntry> filters) {
        var elements = new HashMap<string, string> ();
        var match = false;

        // Add all mandatory and optional elements
        elements.set (UIID, this.id);
        elements.set (NAME, this.name);
        elements.set (DESCRIPTION, this.description);
        elements.set (FORK, this.fork);
        elements.set (LIFETIME, this.lifetime);

        if ((this.name != null) &&
            (this.filters_match (filters, NAME, this.name))) {
            match = true;
        }
        if ((this.description != null) &&
            (this.filters_match (filters, DESCRIPTION, this.description))) {
            match = true;
        }
        if ((this.fork != null) &&
            (this.filters_match (filters, FORK, this.fork))) {
            match = true;
        }
        if ((this.lifetime != null) &&
            (this.filters_match (filters, LIFETIME, this.lifetime))) {
            match = true;
        }

        var sb = new StringBuilder ("<" + UI + ">\n");
        sb.append (this.to_xml (elements));

        var icon_sb = new StringBuilder ();
        foreach (var icon in this.icons) {
            icon_sb.append (icon.to_ui_listing (filters));
        }

        // Only display list if there is something to display
        if (icon_sb.str.length > 0) {
            match = true;
            sb.append ("<" + ICONLIST + ">\n");
            sb.append (icon_sb.str);
            sb.append ("</" + ICONLIST + ">\n");
        }

        var protocol_sb = new StringBuilder ();
        if (this.protocols.size > 0) {
            foreach (var protocol in this.protocols) {
                protocol_sb.append (protocol.to_ui_listing (filters));
            }

            if (protocol_sb.str.length > 0) {
                match = true;
                sb.append (protocol_sb.str);
            }
        }

        sb.append ("</" + UI + ">\n");
        if (match) {
            return sb.str;
        } else {
            return "";
        }
    }
}
