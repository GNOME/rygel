/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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

using Rygel;
using GUPnP;
using DBus;

/**
 * Represents DVB item.
 */
public class Rygel.DVBChannel : MediaItem {
    public static dynamic DBus.Object channel_list;

    private uint cid; /* The DVB Daemon Channel ID */

    public DVBChannel (uint                cid,
                       MediaContainer      parent,
                       dynamic DBus.Object channel_list) throws GLib.Error {
        string id = parent.id + ":" + cid.to_string (); /* UPnP ID */

        base (id,
              parent,
              "Unknown",        /* Title Unknown at this point */
              "Unknown");       /* UPnP Class Unknown at this point */

        this.cid = cid;
        this.channel_list = channel_list;

        this.fetch_metadata ();
    }

    public void fetch_metadata () throws GLib.Error {
        /* TODO: make this async */
        this.title = this.channel_list.GetChannelName (cid);

        bool is_radio = this.channel_list.IsRadioChannel (cid);
        if (is_radio) {
            this.upnp_class = "object.item.audioItem.audioBroadcast";
        } else {
            this.upnp_class = "object.item.videoItem.videoBroadcast";
        }

        this.mime_type = "video/mpeg";
        string uri = this.channel_list.GetChannelURL (cid);
        this.uris.add (uri);
    }
}

