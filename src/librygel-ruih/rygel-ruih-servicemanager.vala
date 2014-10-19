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

using GUPnP;
using Gee;
using Xml;
using GLib;

public class Rygel.RuihServiceManager : Object
{
    private static const string DEVICEPROFILE = "deviceprofile";
    private static const string PROTOCOL = "protocol";
    private static const string PROTOCOL_INFO = "protocolInfo";
    private static const string SHORT_NAME = "shortName";
    private static const string UI = "ui";
    private static const string UILIST = "uilist";

    private static string PRE_RESULT =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        + "<" + UILIST + " xmlns=\"urn:schemas-upnp-org:remoteui:uilist-1-0\" "
        + "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
        + "xsi:schemaLocation=\"urn:schemas-upnp-org:remoteui:uilist-1-0 CompatibleUIs.xsd\">\n";

    private static string POST_RESULT = "</" + UILIST + ">\n";
    private ArrayList<UIElem> ui_list;
    private Object object = null;

    private static RuihServiceManager instance = null;

    internal Cancellable cancellable;
    private string ui_listing_full_path;
    private FileMonitor ui_file_monitor;
    private RuihServiceManager ruih_manager;

    public const string UI_LISTING_FILE_NAME = "UIList.xml";

    public static RuihServiceManager get_default () {
        if (instance == null) {
            instance = new RuihServiceManager ();
        }

        return instance;
    }

    public override void constructed () {
        base.constructed ();

        unowned string config_dir = Environment.get_user_config_dir ();
        this.cancellable = new Cancellable ();
        var ui_listing_directory = Path.build_filename (config_dir, "Rygel");
        this.ui_listing_full_path = Path.build_filename (ui_listing_directory,
                                                         UI_LISTING_FILE_NAME);
        DirUtils.create_with_parents (ui_listing_directory, 0755);

        try {
            this.set_ui_list (ui_listing_full_path);
            var ui_file = File.new_for_path (ui_listing_full_path);
            this.ui_file_monitor = ui_file.monitor_file (FileMonitorFlags.NONE,
                                                         cancellable);
            this.ui_file_monitor.changed.connect ((src, dest, event) => {
                try {
                        ruih_manager.set_ui_list (ui_listing_full_path);
                } catch (RuihServiceError e) {
                    error ("Failed to set UIList for file %s - %s\n",
                           ui_listing_full_path,
                           e.message);
                }
            });
        } catch (Rygel.RuihServiceError e) {
            error ("Failed to set initial UI list for file %s - %s\n",
                  this.ui_listing_full_path, e.message);
        } catch (GLib.IOError e) {
            error ("Failed to monitor the file %s - %s\n",
                   this.ui_listing_full_path,
                   e.message);
        }
    }

    ~RuihServiceManager () {
        this.cancellable.cancel ();
    }

    public void set_ui_list (string ui_list_file_path) throws RuihServiceError {
        lock (object) {
            this.ui_list = new ArrayList<UIElem> ();
            // Empty internal data
            if (ui_list_file_path == null) {
                return;
            }

            Xml.Doc* doc = Parser.parse_file (ui_list_file_path);
            if (doc == null) {
                throw new RuihServiceError.OPERATION_REJECTED
                    ("Unable to parse UI list file: " + ui_list_file_path);
            }

            Xml.Node* ui_list_node = doc->get_root_element ();
            if (ui_list_node != null &&
                ui_list_node->name == UILIST)
            {
                for (Xml.Node* child_node = ui_list_node->children;
                     child_node != null; child_node = child_node->next)
                {
                    if (child_node->name == UI)
                    {
                        this.ui_list.add (new UIElem (child_node));
                    }
                }
            }
            delete doc;
        }
    }

    public string get_compatible_uis (string deviceProfile, string filter)
        throws RuihServiceError {
        lock (object) {
            ArrayList<FilterEntry> filter_entries = new ArrayList<FilterEntry> ();
            Xml.Node* device_profile_node = null;
            Xml.Doc* doc = null;
            // Parse if there is device info

            if (deviceProfile != null && deviceProfile.length > 0) {
                doc = Parser.parse_memory (deviceProfile,
                                                    deviceProfile.length);
                if (doc == null) {
                    throw new RuihServiceError.OPERATION_REJECTED
                        ("Unable to parse device profile data: " + deviceProfile);
                }
                device_profile_node = doc->get_root_element ();
            }

            // If inputDeviceProfile and filter are empty
            // just display all HTML5 UI elements.
            // This is a change from the UPNP-defined behavior
            if (device_profile_node == null && filter == "") {
                filter_entries.add (new FilterEntry (SHORT_NAME, "*HTML5*"));
            }

            // Parse device info to create protocols
            if (device_profile_node != null) {
                if (device_profile_node->name == DEVICEPROFILE) {
                    for (Xml.Node* child_node = device_profile_node->children;
                         child_node != null; child_node = child_node->next) {
                        if (child_node->type == Xml.ElementType.TEXT_NODE) {
                            // ignore text nodes
                            continue;
                        }
                        if (child_node->name == PROTOCOL) {
                            // Get shortName attribute
                            for (Xml.Attr* prop = child_node->properties; prop != null;
                                 prop = prop->next) {
                                if (prop->name == SHORT_NAME &&
                                    prop->children->content != null) {
                                    filter_entries.add (new FilterEntry (SHORT_NAME,
                                                                         prop->children->content));
                                }
                            }
                        }
                        if (child_node->name == PROTOCOL_INFO &&
                            child_node->content != null) {
                            filter_entries.add (new FilterEntry (PROTOCOL_INFO,
                                                                child_node->content));
                        }
                    }// for
                }// if
                delete doc;
            } // outer if

            if (filter.length > 0) {
                var filter_wildcard = (filter == "*" || filter == "\"*\"");

                // Only enable wildcard if deviceprofile is not available
                if (device_profile_node == null && filter_wildcard) {
                    // Wildcard filter entry
                    filter_entries.add (new WildCardFilterEntry ());
                } else if (!filter_wildcard) {
                    // Check if the input UIFilter is in the right format.
                    if ((filter.get_char (0) != '"') ||
                        ((filter.get_char (filter.length - 1) != '"')
                        && (filter.get_char (filter.length - 1) != ','))
                        ||  (!(filter.contains (",")) && filter.contains (";"))) {
                        throw new RuihServiceError.INVALID_FILTER
                            ("Invalid filter: " + filter);
                    }

                    string[] entries = filter.split (",");
                    foreach (unowned string str in entries) {
                        // separator with no content, ignore
                        if (str.length == 0) {
                            continue;
                        }
                        string value = null;
                        // string off quotes
                        var name_value = str.split ("=");
                        if (name_value != null &&
                            name_value.length == 2 &&
                            name_value[1] != null &&
                            name_value[1].length > 2) {
                            if (name_value[1].get_char (0) == '"' &&
                               name_value[1].get_char
                               (name_value[1].length - 1) == '"') {
                                value = name_value[1].substring
                                    (1, name_value[1].length - 1);
                                filter_entries.add (new FilterEntry
                                                    (name_value[0], value));
                            }
                        }
                    }
                }
            }

            // Generate result XML with or without protocols
            StringBuilder result = new StringBuilder (PRE_RESULT);

            if (this.ui_list != null && this.ui_list.size > 0) {
                var result_content = new StringBuilder ();

                foreach (UIElem i in this.ui_list) {
                    UIElem ui = (UIElem)i;
                    result_content.append (ui.to_ui_listing (filter_entries));
                }

                // Return empty string if there is no matching UI for a filter
                if (result_content.str == "") {
                    return "";
                }

                result.append (result_content.str);
            }
            result.append (POST_RESULT);

            return result.str;
        }
    }
} // RygelServiceManager class
