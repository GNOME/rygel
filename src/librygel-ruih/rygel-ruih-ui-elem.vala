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

protected class UIElem : UIListing
{
    private string id = null;
    private string name = null;
    private string description = null;
    private string fork = null;
    private string lifetime = null;

    private Gee.ArrayList<IconElem> icons ;
    private Gee.ArrayList<ProtocolElem> protocols;

    public UIElem (Xml.Node* node) throws Rygel.RuihServiceError
    {
        if (node == null)
        {
            throw new Rygel.RuihServiceError.OPERATION_REJECTED
                ("Unable to parse UI data - null");
        }

        this.icons = new ArrayList<IconElem> ();
        this.protocols = new ArrayList<ProtocolElem> ();

        // invalid XML exception?
        for (Xml.Node* child_node = node->children; child_node != null;
             child_node = child_node->next)
        {
            if (child_node->type == Xml.ElementType.TEXT_NODE) {
                // ignore text nodes
                continue;
            }
            string node_name = child_node->name;
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
                for (Xml.Node* icon_node = child_node->children;
                    icon_node != null; icon_node = icon_node->next)
                {
                    if (icon_node->name == ICON)
                    {
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
                throw new Rygel.RuihServiceError.OPERATION_REJECTED
                        ("Unable to parse UI data - unexpected node: "
                         + node_name);
            }
        }
    }

    public override bool match (Gee.ArrayList<ProtocolElem> protocol_elements,
                               Gee.ArrayList<FilterEntry> filters) {
        if (protocol_elements == null || protocol_elements.size == 0) {
            return true;
        }

        foreach (ProtocolElem prot in protocol_elements) {
            ProtocolElem proto = (ProtocolElem)prot;
            if (proto.match (this.protocols, filters)) {
                return true;
            }
        }

        return false;
    }

    public override string to_ui_listing (Gee.ArrayList<FilterEntry> filters) {
        HashMap<string, string> elements =
            new HashMap<string, string> ();
        bool match = false;
        // Add all mandatory and optional elements
        elements.set (UIID, this.id);
        elements.set (NAME, this.name);
        elements.set (DESCRIPTION, this.description);
        elements.set (FORK, this.fork);
        elements.set (LIFETIME, this.lifetime);

        if ((this.name != null) && (filters_match (filters, NAME, this.name))) {
            match = true;
        }
        if ((this.description != null) && (filters_match (filters, DESCRIPTION,
                                                         this.description))) {
            match = true;
        }
        if ((this.fork != null) && (filters_match (filters, FORK, this.fork))) {
            match = true;
        }
        if ((this.lifetime != null) && (filters_match (filters, LIFETIME,
                                                      this.lifetime))) {
            match = true;
        }

        StringBuilder sb = new StringBuilder ("<" + UI + ">\n");
        sb.append (to_xml (elements));

        StringBuilder icon_sb = new StringBuilder ();
        foreach (IconElem i in this.icons) {
            icon_sb.append (i.to_ui_listing (filters));
        }

        // Only display list if there is something to display
        if (icon_sb.str.length > 0) {
            match = true;
            sb.append ("<" + ICONLIST + ">\n");
            sb.append (icon_sb.str);
            sb.append ("</" + ICONLIST + ">\n");
        }
        StringBuilder protocol_sb = new StringBuilder ();
        if (this.protocols.size > 0) {
            foreach (ProtocolElem i in this.protocols) {
                protocol_sb.append (i.to_ui_listing (filters));
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
