/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

internal enum SerializerType {
    GENERIC_DIDL,
    DIDL_S
}

internal class Rygel.Serializer : Object {
    private DIDLLiteWriter writer;
    private MediaCollection collection;

    public Serializer (SerializerType type) {
        switch (type) {
            case SerializerType.GENERIC_DIDL:
                this.writer = new DIDLLiteWriter (null);
                break;
            case SerializerType.DIDL_S:
                this.collection = new MediaCollection ();
                break;
            default:
                assert_not_reached ();
        }
    }

    public DIDLLiteItem? add_item () {
        if (writer != null) {
            return this.writer.add_item ();
        } else {
            return this.collection.add_item ();
        }
    }

    public DIDLLiteContainer? add_container () {
        if (writer != null) {
            return this.writer.add_container ();
        } else {
            // MediaCollection does not support this.
            return null;
        }
    }

    public void filter (string filter_string) {
        if (writer != null) {
            this.writer.filter (filter_string);
        }
    }

    public string get_string () {
        if (writer != null) {
            return this.writer.get_string ();
        } else {
            return this.collection.get_string ();
        }
    }
}
