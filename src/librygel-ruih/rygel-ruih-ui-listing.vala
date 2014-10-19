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

public abstract class UIListing
{
    protected static const string DESCRIPTION = "description";
    protected static const string FORK = "fork";
    protected static const string ICON = "icon";
    protected static const string ICONLIST = "iconList";
    protected static const string LIFETIME = "lifetime";
    protected static const string NAME = "name";
    protected static const string PROTOCOL = "protocol";
    protected static const string PROTOCOL_INFO = "protocolInfo";
    protected static const string SHORT_NAME = "shortName";
    protected static const string UI = "ui";
    protected static const string URI = "uri";
    protected static const string UIID = "uiID";

    public abstract bool match (ArrayList<ProtocolElem>? protocols,
                                ArrayList<FilterEntry> filters);
    public abstract string to_ui_listing (ArrayList<FilterEntry> filters);

    public string to_xml (Gee.HashMap<string, string> hash_map) {
        var sb = new StringBuilder ();
        foreach (var e in hash_map.entries) {
            sb.append_printf ("<%s>%s</%s>\n", e.key, e.value, e.key);
        }

        return sb.str;
    }

    // Convenience method to avoid a lot of inline loops
    public bool filters_match (ArrayList<FilterEntry>? filters,
                               string? name,
                               string? value) {
        if (filters == null || name == null || value == null) {
            return false;
        }

        foreach (var entry in filters) {
            if ((entry != null) && (entry.matches (name, value))) {
                return true;
            }
        }

        return false;
    }
}
