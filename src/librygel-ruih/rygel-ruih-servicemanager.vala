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

using GUPnP;
using Gee;
using Xml;
using GLib;

public class Rygel.RuihServiceManager : Object
{
    private const string DEVICEPROFILE = "deviceprofile";
    private const string PROTOCOL = "protocol";
    private const string PROTOCOL_INFO = "protocolInfo";
    private const string SHORT_NAME = "shortName";
    private const string UI = "ui";
    private const string UILIST = "uilist";

    private static string PRE_RESULT =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        + "<" + UILIST + " xmlns=\"urn:schemas-upnp-org:remoteui:uilist-1-0\" "
        + "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
        + "xsi:schemaLocation=\"urn:schemas-upnp-org:remoteui:uilist-1-0 "
        + "CompatibleUIs.xsd\">\n";

    private static string POST_RESULT = "</" + UILIST + ">\n";
    private ArrayList<UIElem> ui_list;

    private static RuihServiceManager instance = null;

    internal Cancellable cancellable;
    private string ui_listing_full_path;
    private FileMonitor ui_file_monitor;

    public const string UI_LISTING_FILE_NAME = "UIList.xml";

    public signal void updated ();

    public static RuihServiceManager get_default () {
        if (instance == null) {
            instance = new RuihServiceManager ();
        }

        return instance;
    }

    public override void constructed () {
        base.constructed ();

        this.ui_list = new ArrayList<UIElem> ();

        unowned string config_dir = Environment.get_user_config_dir ();
        this.cancellable = new Cancellable ();
        var ui_listing_directory = Path.build_filename (config_dir, "Rygel");
        this.ui_listing_full_path = Path.build_filename (ui_listing_directory,
                                                         UI_LISTING_FILE_NAME);
        DirUtils.create_with_parents (ui_listing_directory, 0755);

        try {
            this.set_ui_list (ui_listing_full_path);
            var ui_file = File.new_for_path (ui_listing_full_path);
            var config_dir_file = File.new_for_path (ui_listing_directory);
            this.ui_file_monitor = config_dir_file.monitor_directory
                                        (FileMonitorFlags.NONE,
                                         cancellable);
            this.ui_file_monitor.changed.connect ((src, dest, event) => {
                if (ui_file.equal (src)) {
                    try {
                        this.set_ui_list (ui_listing_full_path);
                    } catch (RuihServiceError e) {
                        warning (_("Failed to set UIList for file %s — %s"),
                                 ui_listing_full_path,
                                 e.message);
                    }

                    // Always signal update as the first thing set_ui_list
                    // does is to clear the old list.
                    this.updated ();
                }
            });
        } catch (RuihServiceError e) {
            warning (_("Failed to set initial UI list for file %s — %s"),
                     this.ui_listing_full_path,
                     e.message);
        } catch (IOError e) {
            warning (_("Failed to monitor the file %s — %s"),
                     this.ui_listing_full_path,
                     e.message);
        }
    }

    ~RuihServiceManager () {
        this.cancellable.cancel ();
    }

    public bool ui_list_available () {
        return !this.ui_list.is_empty;
    }

    public void set_ui_list (string ui_list_file_path) throws RuihServiceError {
        this.ui_list.clear ();
        // Empty internal data
        if (ui_list_file_path == null) {
            return;
        }

        var doc = Parser.parse_file (ui_list_file_path);
        if (doc == null) {
            var msg = _("Unable to parse UI list file %s");
            throw new RuihServiceError.OPERATION_REJECTED
                                        (msg.printf (ui_list_file_path));
        }

        var ui_list_node = doc->get_root_element ();
        if (ui_list_node != null && ui_list_node->name == UILIST) {
            foreach (var node in new XMLUtils.ChildIterator (ui_list_node)) {
                if (node->name == UI) {
                    this.ui_list.add (new UIElem (node));
                }
            }
        }

        delete doc;
    }

    public string get_compatible_uis (string device_profile, string filter)
                                      throws RuihServiceError {
        ArrayList<FilterEntry> filter_entries = new ArrayList<FilterEntry> ();
        Xml.Node* device_profile_node = null;
        Xml.Doc* doc = null;
        // Parse if there is device info

        if (device_profile != null && device_profile.length > 0) {
            doc = Parser.parse_memory (device_profile,
                                       device_profile.length);
            if (doc == null) {
                var msg = _("Unable to parse device profile data: %s");
                throw new RuihServiceError.OPERATION_REJECTED
                                        (msg.printf (device_profile));
            }
            device_profile_node = doc->get_root_element ();
        }

        // If inputDeviceProfile and filter are empty
        // just display all HTML5 UI elements.
        // This is a change from the UPnP-defined behavior
        if (device_profile_node == null && filter == "") {
            filter_entries.add (new FilterEntry (SHORT_NAME, "*HTML5*"));
        }

        this.convert_device_profile_to_filter (device_profile_node,
                                               filter_entries);

        this.convert_filter_string (device_profile_node, filter, filter_entries);

        delete doc;

        // Generate result XML with or without protocols
        var result = new StringBuilder (PRE_RESULT);

        if (this.ui_list != null && this.ui_list.size > 0) {
            var result_content = new StringBuilder ();

            foreach (var ui in this.ui_list) {
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

    private void convert_device_profile_to_filter
                                        (Xml.Node *node,
                                         Gee.List<FilterEntry> filter_entries) {
        if (node == null || node->name != DEVICEPROFILE) {
            return;
        }

        foreach (var child_node in new XMLUtils.ChildIterator (node)) {
            if (child_node->type == Xml.ElementType.TEXT_NODE) {
                // ignore text nodes
                continue;
            }

            if (child_node->name == PROTOCOL) {
                // Get shortName attribute
                for (var prop = child_node->properties;
                     prop != null;
                     prop = prop->next) {
                    if (prop->name == SHORT_NAME &&
                        prop->children->content != null) {
                        var entry = new FilterEntry (SHORT_NAME,
                                                     prop->children->content);
                        filter_entries.add (entry);
                    }
                }
            }

            if (child_node->name == PROTOCOL_INFO &&
                child_node->content != null) {
                var entry = new FilterEntry (PROTOCOL_INFO,
                                             child_node->content);
                filter_entries.add (entry);
            }
        }// for
    }

    private void convert_filter_string (Xml.Node *device_profile_node,
                                        string filter,
                                        Gee.List<FilterEntry> filter_entries)
                                        throws RuihServiceError {
        if (filter.length == 0) {
            return;
        }

        var filter_is_wildcard = (filter == "*" || filter == "\"*\"");

        // Only enable wildcard if deviceprofile is not available
        if (device_profile_node == null && filter_is_wildcard) {
            // Wildcard filter entry
            filter_entries.add (new WildCardFilterEntry ());
        } else if (!filter_is_wildcard) {
            // Check if the input UIFilter is in the right format.
            if ((filter.get_char (0) != '"') ||
                ((filter.get_char (filter.length - 1) != '"') &&
                 (filter.get_char (filter.length - 1) != ',')) ||
                (!(filter.contains (",")) && filter.contains (";"))) {
                var msg = _("Invalid UI filter: %s");
                throw new RuihServiceError.INVALID_FILTER (msg.printf (filter));
            }

            var entries = filter.split (",");
            foreach (unowned string str in entries) {
                // separator with no content, ignore
                if (str.length == 0) {
                    continue;
                }

                // string off quotes
                var name_value = str.split ("=");
                if (name_value != null &&
                    name_value.length == 2 &&
                    name_value[1] != null &&
                    name_value[1].length > 2) {
                    if (name_value[1].get_char (0) == '"' &&
                        name_value[1].get_char (name_value[1].length - 1) == '"') {
                        var value = name_value[1].substring
                                        (1, name_value[1].length - 1);
                        filter_entries.add (new FilterEntry
                                            (name_value[0], value));
                    }
                }
            }
        }
    }
} // RygelServiceManager class
