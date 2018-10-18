/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2012,2013 Intel Corporation.
 * Copyright (C) 2015 Jens Georg
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
 *         Jens Georg <mail@jensge.org>
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
using Gst;
using Gst.PbUtils;

/**
 * Represents MediaExport item.
 */
namespace Rygel.MediaExport.ItemFactory {

    internal errordomain ItemFactoryError {
        DESERIALIZATION,
        MISMATCH
    }

    private static bool check_variant_type (Variant v,
                                            string typestring) throws Error {
        if (!v.is_of_type (new VariantType (typestring))) {
            var msg = "Variant type mismatch, expected %s, got %s";
            throw new ItemFactoryError.DESERIALIZATION (msg,
                                                        v.get_type_string (),
                                                        typestring);
        }

        return true;
    }

    static MediaObject? create (MediaContainer parent, VariantDict vd) {
        VariantType? expected = null;
        MediaObject? object = null;

        var upnp_class = vd.lookup_value (Serializer.UPNP_CLASS, expected);
        var id = vd.lookup_value (Serializer.ID, expected);
        var title = vd.lookup_value (Serializer.TITLE, expected);
        var uri = vd.lookup_value (Serializer.URI, expected);

        var factory = new ObjectFactory ();
        if (upnp_class.get_string ().has_prefix (MediaContainer.UPNP_CLASS)) {
            object = factory.get_container (id.get_string (),
                                            title.get_string (),
                                            0,
                                            uri.get_string ());
        } else {
            object = factory.get_item (parent,
                                       id.get_string (),
                                       title.get_string (),
                                       upnp_class.get_string ());
        }

        object.add_uri (uri.get_string ());

        return object;
    }

    static int64 get_int64 (VariantDict vd, string key) {
        var val = vd.lookup_value (key, VariantType.UINT64);
        if (val != null) {
            return (int64) val.get_uint64 ();
        }

        return -1;
    }

    static int32 get_int32 (VariantDict vd, string key) {
        var val = vd.lookup_value (key, VariantType.INT32);
        if (val != null) {
            return val.get_int32 ();
        }

        return -1;
    }


    static MediaObject? create_from_variant (MediaContainer parent,
                                             File           file,
                                             Variant?       v)
                                             throws Error {
        VariantType? expected = null;
        if (v == null) {
            return null;
        }

        ItemFactory.check_variant_type (v,"a{sv}");

        VariantDict vd = new VariantDict (v);

        var upnp_class = vd.lookup_value (Serializer.UPNP_CLASS, expected);
        if (upnp_class == null) {
            debug ("Did not find a UPnP class for item, ignoring");

            return null;
        }

        var object = create (parent, vd);
        if (object is MediaContainer) {
            return object;
        }

        var item = object as MediaFileItem;

        // Fill general things
        var val = vd.lookup_value (Serializer.MIME_TYPE, expected);
        item.mime_type = val.get_string ();

        item.size = get_int64 (vd, Serializer.SIZE);

        val = vd.lookup_value (Serializer.MODIFIED, expected);
        item.modified = val.get_uint64 ();

        val = vd.lookup_value (Serializer.DLNA_PROFILE, expected);
        if (val != null) {
            item.dlna_profile = val.get_string ();
        }

        val = vd.lookup_value (Serializer.DATE, expected);
        if (val != null) {
            item.date = val.get_string ();
        }

        if (item is AudioItem) {
            var audio_item = item as AudioItem;
            audio_item.duration = get_int32 (vd, Serializer.DURATION);
            audio_item.bitrate = get_int32 (vd, Serializer.AUDIO_BITRATE);
            audio_item.channels = get_int32 (vd, Serializer.AUDIO_CHANNELS);
            audio_item.sample_freq = get_int32 (vd, Serializer.AUDIO_RATE);

            if (item is MusicItem) {
                var music_item = item as MusicItem;
                val = vd.lookup_value (Serializer.ARTIST, expected);
                if (val != null) {
                    music_item.artist = val.get_string ();
                }

                val = vd.lookup_value (Serializer.ALBUM, expected);
                if (val != null) {
                    music_item.album = val.get_string ();
                }

                val = vd.lookup_value (Serializer.GENRE, expected);
                if (val != null) {
                    music_item.genre = val.get_string ();
                }

                music_item.track_number = get_int32 (vd,
                                                     Serializer.TRACK_NUMBER);
                music_item.disc = get_int32 (vd, Serializer.VOLUME_NUMBER);
            }
        }

        if (item is VisualItem) {
            var visual_item = item as VisualItem;
            visual_item.width = get_int32 (vd, Serializer.VIDEO_WIDTH);
            visual_item.height = get_int32 (vd, Serializer.VIDEO_HEIGHT);
            visual_item.color_depth = get_int32 (vd, Serializer.VIDEO_DEPTH);
        }

        return item as MediaFileItem;
    }
}
