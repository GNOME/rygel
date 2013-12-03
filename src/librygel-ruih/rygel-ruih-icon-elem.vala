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

protected class IconElem : UIListing {
    private static const string MIMETYPE = "mimetype";
    private static const string WIDTH = "width";
    private static const string HEIGHT = "height";
    private static const string DEPTH = "depth";
    private static const string URL = "url";

    // optional attributes
    private string mime_type = null;
    private string width = null;
    private string height = null;
    private string depth = null;
    private string url = null;

    public IconElem (Xml.Node* node) throws Rygel.RuihServiceError {
        if (node == null) {
            throw new Rygel.RuihServiceError.OPERATION_REJECTED ("Unable to parse Icon data - null");
        }
        // Invalid XML Handling?
        for (Xml.Node* child_node = node->children; child_node != null; child_node = child_node->next) {
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
                throw new Rygel.RuihServiceError.OPERATION_REJECTED ("Unable to parse Icon data - unexpected node: " + node_name);
            }
        }
    }

    public override bool match (Gee.ArrayList<ProtocolElem> protocols, Gee.ArrayList<FilterEntry> filters) {
        return true;
    }

    public override string to_ui_listing (Gee.ArrayList<FilterEntry> filters) {
        HashMap<string, string> elements = new HashMap<string, string> ();
        if ((this.mime_type != null) && (filters_match (filters, ICON + "@" + MIMETYPE, this.mime_type))) {
            elements.set (MIMETYPE, this.mime_type);
        }
        if ((this.width != null) && (filters_match (filters, ICON + "@" + WIDTH, this.width))) {
            elements.set (WIDTH, this.width);
        }
        if ((this.height != null) && (filters_match (filters, ICON + "@" + HEIGHT, this.height))) {
            elements.set (HEIGHT, this.height);
        }
        if ((this.depth != null) && (filters_match (filters, ICON + "@" + DEPTH, this.depth))) {
            elements.set (DEPTH, this.depth);
        }
        if ((this.url != null) && (filters_match (filters, ICON + "@" + URL, this.url))) {
            elements.set (URL, this.url);
        }

        if (elements.size > 0) {
            StringBuilder sb = new StringBuilder ();
            sb.append ("<" + ICON + ">\n");
            sb.append (to_xml (elements));
            sb.append ("</" + ICON + ">\n");
            return sb.str;
        }
        return "";
    }
}