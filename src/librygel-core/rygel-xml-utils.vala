/*
 * Copyright (C) 2008,2010 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using Xml;

/**
 * XML utility API.
 */
public class Rygel.XMLUtils {
    public static Xml.Ns* get_namespace (Xml.Node *root, string href, string prefix) {

        Xml.Ns* ns = root->new_ns (href, prefix);
        if (ns != null) {
            return ns;
        }

        // ns was null, so the namespace exists. Go find it.
        ns = root->ns_def;
        while (ns != null) {
            if (ns->prefix == prefix) {
                return ns;
            }
            ns = ns->next;
        }

        assert_not_reached ();
    }

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

    /**
     * Convenience class to iterate over Xml.Node's siblings in vala's foreach
     * loop.
     */
    public class Iterator {
        private Xml.Node* iter;

        public Iterator (Xml.Node* node) {
            this.iter = node;
        }

        public Iterator iterator() {
            return this;
        }

        public bool next () {
            return this.iter != null;
        }

        public Xml.Node* @get () {
            var current = this.iter;
            this.iter = this.iter->next;

            return current;
        }
    }

    public class ChildIterator : Iterator {
        public ChildIterator (Xml.Node* node) {
            base (node->children);
        }
    }
}
