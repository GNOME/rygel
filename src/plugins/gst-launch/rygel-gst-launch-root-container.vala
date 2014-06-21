/*
 * Copyright (C) 2009 Thijs Vermeir <thijsvermeir@gmail.com>
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
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

/**
 * Represents the root container for GstLaunch content hierarchy.
 */
public class Rygel.GstLaunch.RootContainer : SimpleContainer {
    const string CONFIG_GROUP = "GstLaunch";
    const string ITEM_NAMES = "launch-items";

    MetaConfig config;

    public RootContainer (string title) {
        base.root (title);

        try {
            config = MetaConfig.get_default ();

            var item_names = config.get_string_list (CONFIG_GROUP, ITEM_NAMES);
            foreach (var name in item_names) {
                add_launch_item (name);
            }
        } catch (Error err) {
            debug ("GstLaunch init failed: %s", err.message);
        }
    }

    void add_launch_item (string name) {
        try {
            var title = config.get_string (CONFIG_GROUP,
                                           "%s-title".printf (name));
            var mime_type = config.get_string (CONFIG_GROUP,
                                               "%s-mime".printf (name));
            var launch_line = config.get_string (CONFIG_GROUP,
                                                 "%s-launch".printf (name));
            string dlna_profile = null;
            MediaFileItem item;
            try {
                dlna_profile = config.get_string (CONFIG_GROUP,
                                                  "%s-dlnaprofile".printf
                                                  (name));
            } catch (Error error) {}

            if (mime_type.has_prefix ("audio")) {
                item = new AudioItem (name,
                                      this,
                                      title,
                                      mime_type,
                                      launch_line);
            } else {
                item = new VideoItem (name,
                                      this,
                                      title,
                                      mime_type,
                                      launch_line);
            }

            if (item != null) {
                if (dlna_profile != null) {
                    item.dlna_profile = dlna_profile;
                }
                this.add_child_item (item);
            }
        } catch (GLib.Error err) {
            debug ("GstLaunch failed item '%s': %s", name, err.message);
        }
    }
}

