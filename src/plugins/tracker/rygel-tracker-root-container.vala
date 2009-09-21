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

        this.add_child (new TrackerSearchContainer (
                                        "16",
                                        this,
                                        "Pictures",
                                        TrackerImageItem.SERVICE));
        this.add_child (new TrackerSearchContainer (
                                        "14",
                                        this,
                                        "Music",
                                        TrackerMusicItem.SERVICE));
        this.add_child (new TrackerSearchContainer (
                                        "15",
                                        this,
                                        "Videos",
                                        TrackerVideoItem.SERVICE));
        this.add_child (new TrackerMetadataValues ("Audio:Artist",
                                                   "17",
                                                   this,
                                                   "Artists"));
        this.add_child (new TrackerMetadataValues ("Audio:Album",
                                                   "18",
                                                   this,
                                                   "Albums"));
        this.add_child (new TrackerKeywords ("19", this));
    }
}

