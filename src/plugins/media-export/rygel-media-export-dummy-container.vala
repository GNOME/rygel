/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
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
using Gee;

internal class Rygel.MediaExport.DummyContainer : NullContainer {
    public File file;
    public Gee.List<string> children;

    public DummyContainer (File           file,
                           MediaContainer parent) {
        this.id = MediaCache.get_id (file);
        this.title = file.get_basename ();
        this.parent_ref = parent;
        this.file = file;
        this.uris.add (file.get_uri ());
        try {
            this.children = MediaCache.get_default ().get_child_ids (this.id);
            this.child_count = this.children.size;
        } catch (Error error) {
            this.children = new ArrayList<string> ();
            this.child_count = 0;
        }
    }

    public void seen (File file) {
        this.children.remove (MediaCache.get_id (file));
    }
}
