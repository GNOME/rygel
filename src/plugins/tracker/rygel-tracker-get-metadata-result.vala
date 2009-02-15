/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
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

using Rygel;

/**
 * Handles Tracker Metadata.Get method results.
 *
 * FIXME: This should inherit from Rygel.SimpleAsyncResult once bug#567319 is
 *        fixed.
 */
public class Rygel.TrackerGetMetadataResult : GLib.Object, GLib.AsyncResult {
    protected Object source_object;
    protected AsyncReadyCallback callback;
    protected string item_id;

    public MediaObject data;
    public Error error;

    public TrackerGetMetadataResult (TrackerCategory    category,
                                     AsyncReadyCallback callback,
                                     string             item_id) {
        this.source_object = category;
        this.callback = callback;
        this.item_id = item_id;
    }

    public void ready (string[] metadata, Error error) {
        if (error != null) {
            this.error = error;

            this.complete ();
            return;
        }

        TrackerCategory category = (TrackerCategory) this.source_object;

        string path = category.get_item_path (item_id);
        this.data = category.create_item (path, metadata);

        this.complete ();
    }

    public unowned Object get_source_object () {
        return this.source_object;
    }

    public void* get_user_data () {
        return null;
    }

    public void complete () {
        this.callback (this.source_object, this);
    }

    public void complete_in_idle () {
        Idle.add_full (Priority.DEFAULT, idle_func);
    }

    private bool idle_func () {
        this.complete ();

        return false;
    }
}
