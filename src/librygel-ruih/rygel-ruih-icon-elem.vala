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

protected class IconElem : UIListing {
    private const string MIMETYPE = "mimetype";
    private const string WIDTH = "width";
    private const string HEIGHT = "height";
    private const string DEPTH = "depth";
    private const string URL = "url";

    // optional attributes
    private string mime_type = null;
    private string width = null;
    private string height = null;
    private string depth = null;
    private string url = null;

    public IconElem (Xml.Node* node) throws Rygel.RuihServiceError {
        // Invalid XML Handling?
        foreach (var child_node in new Rygel.XMLUtils.ChildIterator (node)) {
            if (child_node->type == Xml.ElementType.TEXT_NODE) {
                // ignore text nodes
                continue;
            }
            string node_name = child_node->name;
            switch (node_name) {
            case MIMETYPE:
                this.mime_type = child_node->get_content ();
                break;
            case WIDTH:
                this.width = child_node->get_content ();
                break;
            case HEIGHT:
                this.height = child_node->get_content ();
                break;
            case DEPTH:
                this.depth = child_node->get_content ();
                break;
            case URL:
                this.url = child_node->get_content ();
                break;
            default:
                var msg = _("Unable to parse Icon data — unexpected node: %s");
                throw new Rygel.RuihServiceError.OPERATION_REJECTED
                                        (msg.printf (node_name));
            }
        }
    }

    public override bool match (ArrayList<ProtocolElem>? protocols,
                                ArrayList<FilterEntry> filters) {
        return true;
    }

    public override string to_ui_listing (ArrayList<FilterEntry> filters) {
        var elements = new HashMap<string, string> ();

        if ((this.mime_type != null) &&
            (this.filters_match (filters, ICON + "@" + MIMETYPE,
                                 this.mime_type))) {
            elements.set (MIMETYPE, this.mime_type);
        }
        if ((this.width != null) &&
            (this.filters_match (filters, ICON + "@" + WIDTH, this.width))) {
            elements.set (WIDTH, this.width);
        }
        if ((this.height != null) &&
            (this.filters_match (filters, ICON + "@" + HEIGHT, this.height))) {
            elements.set (HEIGHT, this.height);
        }
        if ((this.depth != null) &&
            (this.filters_match (filters, ICON + "@" + DEPTH, this.depth))) {
            elements.set (DEPTH, this.depth);
        }
        if ((this.url != null) &&
            (this.filters_match (filters, ICON + "@" + URL, this.url))) {
            elements.set (URL, this.url);
        }

        if (elements.size > 0) {
            var sb = new StringBuilder ();
            sb.append ("<" + ICON + ">\n");
            sb.append (this.to_xml (elements));
            sb.append ("</" + ICON + ">\n");

            return sb.str;
        }

        return "";
    }
}
