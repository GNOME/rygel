/*
 * Copyright (C) 2009-2012 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

/**
 * Responsible for management of all transcoders:
 * # Gets the appropriate transcoder given a transcoding target.
 * # Provide all possible transcoding resources for items.
 */
public abstract class Rygel.TranscodeManager : GLib.Object {

    private static bool protocol_equal_func (GUPnP.ProtocolInfo a,
                                             GUPnP.ProtocolInfo b) {
        return a.dlna_profile == b.dlna_profile &&
               a.mime_type == b.mime_type;
    }

    public TranscodeManager () { }

    public abstract string create_uri_for_object (MediaObject  item,
                                                  int          thumbnail_index,
                                                  int          subtitle_index,
                                                  string?      transcode_target,
                                                  string?      playlist_target,
                                                  string?      resource_name);

    public void add_resources (DIDLLiteItem didl_item, MediaFileItem item)
                               throws Error {
        var engine = MediaEngine.get_default ();
        var list = new GLib.List<Transcoder> ();
        unowned GLib.List<Transcoder> transcoders = engine.get_transcoders ();

        foreach (var transcoder in transcoders) {
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

        foreach (var iter in MediaEngine.get_default ().get_transcoders ()) {
            if (iter.can_handle (target)) {
                transcoder = iter;
            }
        }

        if (transcoder == null) {
            throw new HTTPRequestError.NOT_FOUND (
                            _("No transcoder available for target format '%s'"),
                            target);
        }

        return transcoder;
    }

    internal abstract string get_protocol ();

    internal virtual ArrayList<ProtocolInfo> get_protocol_info () {
        var engine = MediaEngine.get_default ();
        var protocol_infos = new ArrayList<ProtocolInfo> (protocol_equal_func);
        unowned GLib.List<Transcoder> transcoders = engine.get_transcoders ();

        foreach (var transcoder in transcoders) {
            var protocol_info = new ProtocolInfo ();

            protocol_info.protocol = this.get_protocol ();
            protocol_info.mime_type = transcoder.mime_type;
            protocol_info.dlna_profile = transcoder.dlna_profile;

            protocol_infos.add (protocol_info);
        }

        return protocol_infos;
    }
}
