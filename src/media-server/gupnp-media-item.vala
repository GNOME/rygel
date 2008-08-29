/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

public class GUPnP.MediaItem : MediaObject {
    public static const string IMAGE_CLASS = "object.item.imageItem";
    public static const string VIDEO_CLASS = "object.item.videoItem";
    public static const string MUSIC_CLASS = "object.item.audioItem.musicTrack";

    public string mime;
    public string author;
    public string album;
    public string date;
    public string upnp_class;
    public string uri;

    public int width = -1;
    public int height = -1;
    public int track_number = -1;

    public MediaItem (string id,
                      string parent_id,
                      string title,
                      string upnp_class) {
        this.id = id;
        this.parent_id = parent_id;
        this.title = title;
        this.upnp_class = upnp_class;
    }

    public override void serialize (DIDLLiteWriter didl_writer) {
        didl_writer.start_item (this.id,
                                this.parent_id,
                                null,
                                false);

        /* Add fields */
        didl_writer.add_string ("title",
                                DIDLLiteWriter.NAMESPACE_DC,
                                null,
                                this.title);

        didl_writer.add_string ("class",
                                DIDLLiteWriter.NAMESPACE_UPNP,
                                null,
                                this.upnp_class);

        if (this.author != null && this.author != "") {
            didl_writer.add_string ("creator",
                                    DIDLLiteWriter.NAMESPACE_DC,
                                    null,
                                    this.author);

            if (this.upnp_class == VIDEO_CLASS) {
                didl_writer.add_string ("author",
                                        DIDLLiteWriter.NAMESPACE_UPNP,
                                        null,
                                        this.author);
            } else if (this.upnp_class == MUSIC_CLASS) {
                didl_writer.add_string ("artist",
                                        DIDLLiteWriter.NAMESPACE_UPNP,
                                        null,
                                        this.author);
            }
        }

        if (this.track_number >= 0) {
            didl_writer.add_int ("originalTrackNumber",
                                 DIDLLiteWriter.NAMESPACE_UPNP,
                                 null,
                                 this.track_number);
        }

        if (this.album != null && this.album != "") {
            didl_writer.add_string ("album",
                                    DIDLLiteWriter.NAMESPACE_UPNP,
                                    null,
                                    this.album);
        }

        if (this.date != null && this.date != "") {
            didl_writer.add_string ("date",
                                    DIDLLiteWriter.NAMESPACE_DC,
                                    null,
                                    this.date);
        }

        /* Add resource data */
        DIDLLiteResource res;

        res.reset ();

        /* URI */
        res.uri = uri;

        /* Protocol info */
        res.protocol = "http-get";
        res.mime_type = mime;
        res.dlna_profile = "MP3"; /* FIXME */

        res.width = width;
        res.height = height;

        didl_writer.add_res (res);

        /* FIXME: These lines should be remove once GB#526552 is fixed */
        res.uri = null;
        res.protocol = null;
        res.mime_type = null;
        res.dlna_profile = null;

        /* End of item */
        didl_writer.end_item ();
    }
}
