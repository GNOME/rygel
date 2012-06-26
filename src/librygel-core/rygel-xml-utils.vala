/*
 * Copyright (C) 2008,2010 Nokia Corporation.
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

using Xml;

/**
 * XML utility API.
 */
public class Rygel.XMLUtils {
    /* Copy-paste from gupnp and ported to Vala. */
    public static Xml.Node* get_element (Xml.Node *node, ...) {
        Xml.Node *ret = node;

        var list = va_list ();

        while (true) {
            string arg = list.arg ();
            if (arg == null)
                break;

            for (ret = ret->children; ret != null; ret = ret->next)
                if (arg == ret->name)
                    break;

            if (ret == null)
                break;
        }

        return ret;
    }
}
