/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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
 * Glue's our C code to Vala world.
 */
namespace CStuff {
    /**
     * Holds constants defined by build system.
     */
    class BuildConfig {
        [CCode (cname = "DATA_DIR")]
        public static const string DATA_DIR;

        [CCode (cname = "PLUGIN_DIR")]
        public static const string PLUGIN_DIR;

        [CCode (cname = "PACKAGE_NAME")]
        public static const string PACKAGE_NAME;
    }

    /**
     * Provides utility functions implemented in C.
     */
    public class Utils {
        [CCode (cname = "get_xml_element", cheader_filename = "cstuff.h")]
        public static weak Xml.Node * get_xml_element (Xml.Node node,
                                                       ...);
        [CCode (cname = "generate_random_udn", cheader_filename = "cstuff.h")]
        public static string generate_random_udn ();

        public delegate void ApplicationExitCb ();

        [CCode (cname = "on_application_exit", cheader_filename = "cstuff.h")]
        public static void on_application_exit
                                        (ApplicationExitCb app_exit_cb);
    }
}
