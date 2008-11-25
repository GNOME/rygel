/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak).
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

namespace CStuff {
    class BuildConfig {
        [CCode (cname = "DATA_DIR")]
        public static const string DATA_DIR;

        [CCode (cname = "PLUGIN_DIR")]
        public static const string PLUGIN_DIR;
    }

    public class Utils {
        [CCode (cname = "get_xml_element")]
        public static weak Xml.Node * get_xml_element (Xml.Node node,
                                                       ...);
        [CCode (cname = "generate_random_udn")]
        public static string generate_random_udn ();
    }
}
