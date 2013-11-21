/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

using Rygel;

public class Rygel.LMS.MusicRoot : Rygel.SimpleContainer {
    public MusicRoot (string         id,
                      MediaContainer parent,
                      string         title,
                      LMS.Database   lms_db) {
        base (id, parent, title);

        this.add_child_container (new AllMusic (this, lms_db));
        this.add_child_container (new Artists ("artists", this, _("Artists"), lms_db));
        this.add_child_container (new Albums (this, lms_db));
    }
}
