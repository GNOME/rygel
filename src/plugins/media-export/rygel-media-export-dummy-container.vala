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
    public ArrayList<string> seen_children;

    public DummyContainer (File file, MediaContainer parent) {
        var id = Checksum.compute_for_string (ChecksumType.MD5,
                                              file.get_uri ());
        this.id = id;
        this.parent = parent;
        this.title = file.get_basename ();
        this.child_count = 0;
        this.parent_ref = parent;
        this.file = file;
        this.uris.add (file.get_uri ());
        this.seen_children = new ArrayList<string> (str_equal);
    }

    public void seen (string id) {
        seen_children.add (id);
    }
}
