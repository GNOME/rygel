/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLE TELEVISION LABORATORIES
 * INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 */

using Gee;
using Xml;

protected class ProtocolElem : UIListing {
    private string short_name = null;
    private string protocol_info = null;
    private Gee.ArrayList<string> uris;

    public ProtocolElem (Xml.Node* node) throws Rygel.RuihServiceError {
        this.uris = new ArrayList<string> ();

        for (var prop = node->properties; prop != null; prop = prop->next) {
            var attr_name = prop->name;
            switch (attr_name) {
            case SHORT_NAME:
                this.short_name = prop->children->content;
                break;
            default:
                var msg = _("Unable to parse Protocol data - unexpected attribute: %s");
                throw new Rygel.RuihServiceError.OPERATION_REJECTED
                                        (msg.printf (attr_name));
            }
        }

        foreach (var child_node in new Rygel.XMLUtils.ChildIterator (node)) {
            if (child_node->type == Xml.ElementType.TEXT_NODE) {
                // ignore text nodes
                continue;
            }

            var node_name = child_node->name;
            switch (node_name) {
            case URI:
                this.uris.add (child_node->get_content ());
                break;
            case PROTOCOL_INFO:
                this.protocol_info = child_node->get_content ();
                break;
            default:
                var msg = _("Unable to parse Protocol data - unexpected node: %s");
                throw new Rygel.RuihServiceError.OPERATION_REJECTED
                                        (msg.printf (node_name));
            }
        }
    }

    public string get_short_name () {
        return this.short_name;
    }

    public string get_protocol_info () {
        return this.protocol_info;
    }

    public override bool match (Gee.ArrayList<ProtocolElem>? protocols,
                                Gee.ArrayList filters) {
        if (protocols == null || protocols.size == 0) {
            return true;
        }

        foreach (var proto in protocols) {
            if (this.short_name == proto.get_short_name ()) {
                // Optionally if a protocolInfo is specified
                // match on that as well.
                if (proto.get_protocol_info () != null &&
                    proto.get_protocol_info ()._strip ().length > 0) {
                    if (proto.get_protocol_info () == this.protocol_info) {
                        return true;
                    }
                } else {
                   return true;
                }
            }
        }

        return false;
    }

    public override string to_ui_listing (ArrayList<FilterEntry> filters) {
        var matches = false;
        var elements = new HashMap<string, string> ();

        if ((this.short_name != null) &&
            (this.filters_match (filters, SHORT_NAME, this.short_name))) {
            matches = true;
        }

        if ((this.protocol_info != null) &&
            (this.filters_match (filters, PROTOCOL_INFO, this.protocol_info))) {
            elements.set (PROTOCOL_INFO, this.protocol_info);
            matches = true;
        }

        var sb = new StringBuilder ();
        if (matches) {
            sb.append ("<" + PROTOCOL + " " +
                       SHORT_NAME + "=\""  + this.short_name + "\">\n");

            if (this.uris.size > 0) {
                foreach (var uri in this.uris)
                {
                    sb.append ("<").append (URI).append (">")
                      .append (uri)
                      .append ("</").append (URI).append (">\n");
                }
            }
            sb.append (this.to_xml (elements));
            sb.append ("</" + PROTOCOL + ">\n");
        }

        return sb.str;
    }
}
