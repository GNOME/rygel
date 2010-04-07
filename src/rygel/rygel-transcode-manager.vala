/*
 * Copyright (C) 2009 Nokia Corporation.
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
using Gee;
using Gst;

/**
 * Responsible for management of all transcoders:
 *    - gets the appropriate transcoder given a transcoding target.
 *    - provide all possible transcoding resources for items.
 */
internal abstract class Rygel.TranscodeManager : GLib.Object {
    private ArrayList<Transcoder> transcoders;

    public TranscodeManager () throws GLib.Error {
        transcoders = new ArrayList<Transcoder> ();

        var config = MetaConfig.get_default ();

        if (config.get_transcoding ()) {
            if (config.get_lpcm_transcoder ()) {
                transcoders.add (new L16Transcoder (Endianness.BIG));
            }
            if (config.get_mp3_transcoder ()) {
                transcoders.add (new MP3Transcoder (MP3Layer.THREE));
            }
            if (config.get_mp2ts_transcoder ()) {
                transcoders.add (new MP2TSTranscoder(MP2TSProfile.SD));
                transcoders.add (new MP2TSTranscoder(MP2TSProfile.HD));
            }

            if (config.get_wmv_transcoder ()) {
                transcoders.add (new WMVTranscoder ());
            }
        }
    }

    public abstract string create_uri_for_item (MediaItem  item,
                                                int        thumbnail_index,
                                                int        subtitle_index,
                                                string?    transcode_target);

    public virtual void add_resources (DIDLLiteItem didl_item,
                                       MediaItem    item)
                                       throws Error {
        var list = new GLib.List<Transcoder> ();

        foreach (var transcoder in this.transcoders) {
            if (transcoder.get_distance (item) != uint.MAX) {
                list.append (transcoder);
            }
        }

        list.sort_with_data (item.compare_transcoders);
        foreach (var transcoder in list) {
            transcoder.add_resource (didl_item, item, this);
        }
    }

    public Transcoder get_transcoder (string  target) throws Error {
        Transcoder transcoder = null;

        foreach (var iter in this.transcoders) {
            if (iter.can_handle (target)) {
                transcoder = iter;
            }
        }

        if (transcoder == null) {
            throw new HTTPRequestError.NOT_FOUND (
                            "No transcoder available for target format '%s'",
                            target);
        }

        return transcoder;
    }

    internal abstract string get_protocol ();

    internal virtual string get_protocol_info () {
        string protocol_info = "";

        foreach (var transcoder in this.transcoders) {
            if (protocol_info != "")   // No comma before the first one
                protocol_info += ",";

            protocol_info += this.get_protocol () +
                             ":*:" + transcoder.mime_type +
                             ":DLNA.ORG_PN=" + transcoder.dlna_profile;
        }

        return protocol_info;
    }
}

