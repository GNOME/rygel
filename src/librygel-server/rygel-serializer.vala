/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;

public enum Rygel.SerializerType {
    /// Normal serialization of container/item using DIDL-Lite
    GENERIC_DIDL,

    /// Special version of a DIDL-Lite document for playlists, defined by DLNA
    DIDL_S,

    /// M3UEXT format as used by various media players
    M3UEXT
}

/**
 * Proxy class hiding the different serializers (DIDL, DIDL_S, M3U) behind a
 * single implementation.
 */
public class Rygel.Serializer : Object {
    private DIDLLiteWriter writer;
    private MediaCollection collection;
    private M3UPlayList playlist;

    // private properties
    public SerializerType serializer_type { construct; private get; }

    public Serializer (SerializerType type) {
        Object (serializer_type: type);
    }

    public override void constructed () {
        switch (this.serializer_type) {
            case SerializerType.GENERIC_DIDL:
                this.writer = new DIDLLiteWriter (null);
                break;
            case SerializerType.DIDL_S:
                this.collection = new MediaCollection ();
                break;
            case SerializerType.M3UEXT:
                this.playlist = new M3UPlayList ();
                break;
            default:
                assert_not_reached ();
        }

        base.constructed ();
    }

    public DIDLLiteItem? add_item () {
        switch (this.serializer_type) {
            case SerializerType.GENERIC_DIDL:
                return this.writer.add_item ();
            case SerializerType.DIDL_S:
                return this.collection.add_item ();
            case SerializerType.M3UEXT:
                return this.playlist.add_item ();
            default:
                return null;
        }
    }

    public DIDLLiteContainer? add_container () {
        if (this.writer != null) {
            return this.writer.add_container ();
        } else {
            return null;
        }
    }

    public void filter (string filter_string) {
        if (writer != null) {
            this.writer.filter (filter_string);
        }
    }

    public string get_string () {
        switch (this.serializer_type) {
            case SerializerType.GENERIC_DIDL:
                return this.writer.get_string ();
            case SerializerType.DIDL_S:
                return this.collection.get_string ();
            case SerializerType.M3UEXT:
                return this.playlist.get_string ();
            default:
                return "";
        }
    }
}
