/*
 * Copyright (C) 2009 Nokia Corporation.
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

using Gee;

/**
 * Handles Tracker Search.Query method results.
 *
 */
public class Rygel.TrackerSearchResult :
             Rygel.SimpleAsyncResult<Gee.List<MediaObject>> {
    public TrackerSearchResult (TrackerSearchContainer search_container,
                                AsyncReadyCallback     callback) {
        base (search_container, callback);

        this.data = new ArrayList<MediaObject> ();
    }

    public void ready (string[][] search_result, GLib.Error error) {
        if (error != null) {
            this.error = error;

            this.complete ();
            return;
        }

        var search_container = (TrackerSearchContainer) this.source_object;

        /* Iterate through all items */
        for (uint i = 0; i < search_result.length; i++) {
            string child_path = search_result[i][0];
            string service = search_result[i][1];
            string[] metadata = this.slice_strv_tail (search_result[i], 2);

            var item = search_container.create_item (service,
                                                     child_path,
                                                     metadata);
            this.data.add (item);
        }

        this.complete ();
    }

    /**
     * Chops the tail of a string array.
     *
     * param strv the string to chop the tail of.
     * param index index of the first element in the tail.
     *
     * FIXME: Stop using it once vala supports array[N:M] syntax.
     */
    private string[] slice_strv_tail (string[] strv, int index) {
        var strv_length = this.get_strv_length (strv);
        string[] slice = new string[strv_length - index];

        for (int i = 0; i < slice.length; i++) {
            slice[i] = strv[i + index];
        }

        return slice;
    }

    /**
     * Gets the length of a null-terminated string array
     *
     * param strv the string to compute length of
     *
     * FIXME: Temporary hack, don't use once bug#571322 is fixed
     */
    private int get_strv_length (string[] strv) {
        int i = 0;

        for (i = 0; strv[i] != null; i++);

        return i + 1;
    }
}

