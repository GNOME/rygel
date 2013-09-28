/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2006, 2007, 2008 OpenedHand Ltd.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jorn Baayen <jorn.baayen@gmail.com>
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

/**
 * Responsible for handling HTTP GET & HEAD client requests.
 */
internal class Rygel.HTTPGet : HTTPRequest {
    private const string TRANSFER_MODE_HEADER = "transferMode.dlna.org";

    public Thumbnail thumbnail;
    public Subtitle subtitle;
    public HTTPSeek seek;

    private int thumbnail_index;
    private int subtitle_index;

    public HTTPGetHandler handler;

    public HTTPGet (HTTPServer   http_server,
                    Soup.Server  server,
                    Soup.Message msg) {
        base (http_server, server, msg);

        this.thumbnail_index = -1;
        this.subtitle_index = -1;
    }

    protected override async void handle () throws Error {
        var header = this.msg.request_headers.get_one
                                        ("getcontentFeatures.dlna.org");

        /* We only entertain 'HEAD' and 'GET' requests */
        if ((this.msg.method != "HEAD" && this.msg.method != "GET") ||
            (header != null && header != "1")) {
            throw new HTTPRequestError.BAD_REQUEST (_("Invalid Request"));
        }

        if (uri.transcode_target != null) {
            var transcoder = this.http_server.get_transcoder
                                        (uri.transcode_target);
            this.handler = new HTTPTranscodeHandler (transcoder,
                                                     this.cancellable);
        }

        if (uri.playlist_format != null &&
            HTTPPlaylistHandler.is_supported (uri.playlist_format)) {
            this.handler = new HTTPPlaylistHandler (uri.playlist_format,
                                                    this.cancellable);
        }

        if (this.handler == null) {
            this.handler = new HTTPIdentityHandler (this.cancellable);
        }

        this.ensure_correct_mode ();

        yield this.handle_item_request ();
    }

    protected override async void find_item () throws Error {
        yield base.find_item ();

        // No need to do anything here, will be done in PlaylistHandler
        if (this.object is MediaContainer) {
            return;
        }

        if (unlikely ((this.object as MediaItem).place_holder)) {
            throw new HTTPRequestError.NOT_FOUND ("Item '%s' is empty",
                                                  this.object.id);
        }

        if (this.hack != null) {
            this.hack.apply (this.object);
        }

        if (this.uri.thumbnail_index >= 0) {
            if (this.object is MusicItem) {
                var music = this.object as MusicItem;
                this.thumbnail = music.album_art;

                return;
            } else if (this.object is VisualItem) {
                var visual = this.object as VisualItem;
                if (this.uri.thumbnail_index < visual.thumbnails.size) {
                    this.thumbnail = visual.thumbnails.get
                                            (this.uri.thumbnail_index);

                    return;
                }
            }

            throw new HTTPRequestError.NOT_FOUND
                                        ("No Thumbnail available for item '%s",
                                         this.object.id);
        }

        if (this.uri.subtitle_index >= 0 && this.object is VideoItem) {
            var video = this.object as VideoItem;

            if (this.uri.subtitle_index < video.subtitles.size) {
                this.subtitle = video.subtitles.get (this.uri.subtitle_index);

                return;
            }

            throw new HTTPRequestError.NOT_FOUND
                                        ("No subtitles available for item '%s",
                                         this.object.id);
        }
    }

    private async void handle_item_request () throws Error {
        var need_time_seek = HTTPTimeSeek.needed (this);
        var requested_time_seek = HTTPTimeSeek.requested (this);
        var need_byte_seek = HTTPByteSeek.needed (this);
        var requested_byte_seek = HTTPByteSeek.requested (this);

        if ((requested_time_seek && !need_time_seek) ||
            (requested_byte_seek && !need_byte_seek)) {
            throw new HTTPRequestError.UNACCEPTABLE ("Invalid seek request");
        }

        try {
            if (need_time_seek && requested_time_seek) {
                this.seek = new HTTPTimeSeek (this);
            } else if (need_byte_seek && requested_byte_seek) {
                this.seek = new HTTPByteSeek (this);
            }
        } catch (HTTPSeekError error) {
            this.server.unpause_message (this.msg);

            if (error is HTTPSeekError.INVALID_RANGE) {
                this.end (Soup.Status.BAD_REQUEST);
            } else if (error is HTTPSeekError.OUT_OF_RANGE) {
                this.end (Soup.Status.REQUESTED_RANGE_NOT_SATISFIABLE);
            } else {
                throw error;
            }

            return;
        }

        // Add headers
        this.handler.add_response_headers (this);

        // Add general headers
        if (this.msg.request_headers.get_one ("Range") != null) {
            this.msg.set_status (Soup.Status.PARTIAL_CONTENT);
        } else {
            this.msg.set_status (Soup.Status.OK);
        }

        if (this.handler.knows_size (this)) {
            this.msg.response_headers.set_encoding (Soup.Encoding.CONTENT_LENGTH);
        } else {
            this.msg.response_headers.set_encoding (Soup.Encoding.EOF);
        }

        debug ("Following HTTP headers appended to response:");
        this.msg.response_headers.foreach ((name, value) => {
            debug ("%s : %s", name, value);
        });

        if (this.msg.method == "HEAD") {
            // Only headers requested, no need to send contents
            this.server.unpause_message (this.msg);

            return;
        }

        var response = this.handler.render_body (this);

        yield response.run ();

        this.end (Soup.Status.NONE);
    }

    private void ensure_correct_mode () throws HTTPRequestError {
        var mode = this.msg.request_headers.get_one (TRANSFER_MODE_HEADER);
        var correct = true;

        switch (mode) {
        case "Streaming":
            correct = (!(this.handler is HTTPPlaylistHandler)) && (
                      (this.handler is HTTPTranscodeHandler ||
                      ((this.object as MediaItem).streamable () &&
                       this.subtitle == null &&
                       this.thumbnail == null)));

            break;
        case "Interactive":
            correct = (this.handler is HTTPIdentityHandler &&
                      ((!(this.object as MediaItem).is_live_stream () &&
                       !(this.object as MediaItem).streamable ()) ||
                       (this.subtitle != null ||
                        this.thumbnail != null))) ||
                      this.handler is HTTPPlaylistHandler;

            break;
        }

        if (!correct) {
            throw new HTTPRequestError.UNACCEPTABLE
                                        ("%s mode not supported for '%s'",
                                         mode,
                                         this.object.id);
        }
    }
}
