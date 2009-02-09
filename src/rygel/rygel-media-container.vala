/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

/**
 * Represents a container (folder) for media items and containers. Provides
 * basic serialization (to DIDLLiteWriter) implementation. Deriving classes
 * are supposed to provide working implementations of get_children and
 * find_object.
 */
public abstract class Rygel.MediaContainer : MediaObject {
    public uint child_count;
    public uint32 update_id;

    public MediaContainer (string id,
                           string parent_id,
                           string title,
                           uint   child_count) {
        this.id = id;
        this.parent_id = parent_id;
        this.title = title;
        this.child_count = child_count;
        this.update_id = uint32.MAX; // undefined for non-root containers
    }

    public MediaContainer.root (string title,
                                uint   child_count) {
        this ("0", "-1", title, child_count);
        this.update_id = 0;
    }

   /**
     * Fetches the list of media objects directly under this container.
     *
     * @param offet zero-based index of the first item to return
     * @param max_count maximum number of objects to return
     *
     * return A list of media objects.
     */
    public abstract Gee.List<MediaObject>? get_children (uint offset,
                                                         uint max_count)
                                                         throws Error;

   /**
     * Recursively searches for media object with the given id in this
     * container.
     *
     * @param id ID of the media object to search for.
     *
     * return the found media object.
     */
    public abstract MediaObject? find_object (string id) throws Error;
}

/**
  * A simple implementation of GLib.AsyncResult, very similar to
  * GLib.SimpleAsyncResult that provides holders for a string, object and
  * error reference.
  */
public class Rygel.SimpleAsyncResult : GLib.Object, GLib.AsyncResult {
    private Object source_object;
    private AsyncReadyCallback callback;

    public string str;
    public Object obj;

    public Error error;

    public SimpleAsyncResult (Object             source_object,
                              AsyncReadyCallback callback,
                              Object?            obj,
                              string?            str) {
        this.source_object = source_object;
        this.callback = callback;

        this.obj = obj;
        this.str = str;
    }

    public SimpleAsyncResult.from_error (Object             source_object,
                                         AsyncReadyCallback callback,
                                         Error              error) {
        this.source_object = source_object;
        this.callback = callback;

        this.error = error;
    }

    public unowned GLib.Object get_source_object () {
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

