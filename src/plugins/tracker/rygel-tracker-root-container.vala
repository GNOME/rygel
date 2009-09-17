/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using GUPnP;
using DBus;
using Gee;

/**
 * Represents the root container for Tracker media content hierarchy.
 */
public class Rygel.TrackerRootContainer : Rygel.SimpleContainer {
    public TrackerRootContainer (string title) {
        base.root (title);

        this.children.add (new TrackerImageCategory ("16",
                                                     this,
                                                     "Pictures"));
        this.children.add (new TrackerMusicCategory ("14",
                                                     this,
                                                     "Music"));
        this.children.add (new TrackerVideoCategory ("15",
                                                     this,
                                                     "Videos"));
        this.children.add (new TrackerMetadataValues ("Audio:Artist",
                                                      "17",
                                                      this,
                                                      "Artists"));
        this.children.add (new TrackerMetadataValues ("Audio:Album",
                                                      "18",
                                                      this,
                                                      "Albums"));

        // Now we know how many top-level containers we have
        this.child_count = this.children.size;
    }
}

