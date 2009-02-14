/*
 * Copyright (C) 2009 Zeeshan Ali <zeenix@gmail.com>.
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

/**
 * A simple implementation of GLib.AsyncResult, very similar to
 * GLib.SimpleAsyncResult that provides holders for generic and error
 * reference/values.
 */
public class Rygel.SimpleAsyncResult<G> : GLib.Object, GLib.AsyncResult {
    protected Object source_object;
    protected AsyncReadyCallback callback;

    public G data;
    public Error error;

    public SimpleAsyncResult (Object             source_object,
                              AsyncReadyCallback callback) {
        this.source_object = source_object;
        this.callback = callback;
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

