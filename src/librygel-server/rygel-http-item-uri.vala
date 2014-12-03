/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Authors: Jens Georg <mail@jensge.org>
 *          Zeeshan Ali (Khattak) <zeeshan.ali@nokia.com>
 *                                <zeeshanak@gnome.org>
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

internal class Rygel.HTTPItemURI : Object {
    public string item_id { get; set; }
    public int thumbnail_index { get; set; default = -1; }
    public int subtitle_index { get; set; default = -1; }
    public string? transcode_target { get; set; default = null; }
    public string? playlist_format { get; set; default = null; }
    public string? resource_name { get; set; default = null; }
    public unowned HTTPServer http_server { get; set; }

    private string real_extension;
    public string extension {
        owned get {
            if (this.real_extension != "") {
                return "." + this.real_extension;
            }
            return "";
        }
        set {
            this.real_extension = value;
        }
    }

    public static HashMap<string, string> mime_to_ext;

    public HTTPItemURI (MediaObject object,
                        HTTPServer http_server,
                        int        thumbnail_index = -1,
                        int        subtitle_index = -1,
                        string?    transcode_target = null,
                        string?    playlist_format = null,
                        string?    resource_name = null) {
        this.item_id = object.id;
        this.thumbnail_index = thumbnail_index;
        this.subtitle_index = subtitle_index;
        this.transcode_target = transcode_target;
        this.http_server = http_server;
        this.playlist_format = playlist_format;
        this.resource_name = resource_name;
        this.extension = "";

        if (this.resource_name != null) {
            var resource = object.get_resource_by_name
                                    (this.resource_name);
            if (resource != null) {
                this.extension = resource.extension;
            }

            return;
        } else {
            if (!(object is MediaFileItem)) {
                return;
            }
        }

        var item = object as MediaFileItem;
        if (thumbnail_index > -1) {
            if (item is VisualItem) {
                var thumbnails = (item as VisualItem).thumbnails;

                if (thumbnails.size > thumbnail_index) {
                    this.extension = thumbnails[thumbnail_index].file_extension;
                }
            } else if (item is MusicItem) {
                var album_art = (item as MusicItem).album_art;

                if (album_art != null) {
                    this.extension = album_art.file_extension;
                }
            }
        } else if (subtitle_index > -1) {
            if (item is VideoItem) {
                var subtitles = (item as VideoItem).subtitles;

                if (subtitles.size > subtitle_index) {
                    this.extension = subtitles[subtitle_index].caption_type;
                }
            }
        } else if (transcode_target != null) {
            try {
                var tc = this.http_server.get_transcoder (transcode_target);

                this.extension = tc.extension;
            } catch (Error error) {}
        }

        if (this.extension == "") {
            string uri_extension = "";

            foreach (string uri_string in item.get_uris ()) {
                string basename = Path.get_basename (uri_string);
                int dot_index = basename.last_index_of(".");

                if (dot_index > -1) {
                    uri_extension = basename.substring (dot_index + 1);

                    break;
                }
            }

            if (uri_extension == "") {
                this.extension = this.ext_from_mime_type (item.mime_type);
            } else {
                this.extension = uri_extension;
            }
        }
    }

    // Base 64 Encoding with URL and Filename Safe Alphabet
    // http://tools.ietf.org/html/rfc4648#section-5
    private string base64_urlencode (string data) {
        var enc64 = Base64.encode ((uchar[]) data.to_utf8 ());
        enc64 = enc64.replace ("/", "_");

        return enc64.replace ("+", "-");
    }

    private uchar[] base64_urldecode (string data) {
       var dec64 = data.replace ("_", "/");
       dec64 = dec64.replace ("-", "+");

       return Base64.decode (dec64);
    }

    public HTTPItemURI.from_string (string     uri,
                                    HTTPServer http_server)
                                    throws HTTPRequestError {
        // do not decode the path here as it may contain encoded slashes
        this.thumbnail_index = -1;
        this.subtitle_index = -1;
        this.transcode_target = null;
        this.http_server = http_server;
        this.extension = "";

        var request_uri = uri.replace (http_server.path_root, "");
        var parts = request_uri.split ("/");

        if (parts.length < 2 || parts.length % 2 == 0) {
            throw new HTTPRequestError.BAD_REQUEST (_("Invalid URI '%s'"),
                                                    request_uri);
        }

        string last_part = parts[parts.length - 1];
        int dot_index = last_part.last_index_of (".");

        if (dot_index > -1) {
            this.extension = last_part.substring (dot_index + 1);
            parts[parts.length - 1] = last_part.substring (0, dot_index);
        }

        for (int i = 1; i < parts.length - 1; i += 2) {
            switch (parts[i]) {
                case "i":
                    var data = this.base64_urldecode
                                        (Soup.URI.decode (parts[i + 1]));
                    StringBuilder builder = new StringBuilder ();
                    builder.append ((string) data);
                    this.item_id = builder.str;

                    break;
                case "tr":
                    this.transcode_target = Soup.URI.decode (parts[i + 1]);

                    break;
                case "th":
                    this.thumbnail_index = int.parse (parts[i + 1]);

                    break;
                case "sub":
                    this.subtitle_index = int.parse (parts[i + 1]);

                    break;
                case "pl":
                    this.playlist_format = Soup.URI.decode (parts[i + 1]);

                    break;
                case "res":
                    this.resource_name = Soup.URI.decode (parts[i + 1]);

                    break;
                default:
                    break;
            }
        }

        if (this.item_id == null) {
            throw new HTTPRequestError.NOT_FOUND (_("Not found"));
        }
    }

    public string to_string() {
        // there seems to be a problem converting strings properly to arrays
        // you need to call to_utf8() and assign it to a variable to make it
        // work properly

        var data = this.base64_urlencode (this.item_id);
        var escaped = Uri.escape_string (data, "", true);
        string path = "/i/" + escaped;

        if (this.transcode_target != null) {
            escaped = Uri.escape_string (this.transcode_target, "", true);
            path += "/tr/" + escaped;
        } else if (this.thumbnail_index >= 0) {
            path += "/th/" + this.thumbnail_index.to_string ();
        } else if (this.subtitle_index >= 0) {
            path += "/sub/" + this.subtitle_index.to_string ();
        } else if (this.playlist_format != null) {
            path += "/pl/" + Uri.escape_string
                                        (this.playlist_format, "", true);
        } else if (this.resource_name != null) {
            path += "/res/" + Uri.escape_string
                                        (this.resource_name, "", true);
        }
        path += this.extension;

        return this.create_uri_for_path (path);
    }

    private string create_uri_for_path (string path) {
        return "http://%s:%u%s%s".printf (this.http_server.context.host_ip,
                                          this.http_server.context.port,
                                          this.http_server.path_root,
                                          path);
    }

    private string ext_from_mime_type (string mime_type) {
        if (mime_to_ext == null) {
            mime_to_ext = new HashMap<string, string> ();
            // videos
            string[] videos = {"mpeg", "webm", "ogg"};

            foreach (string video in videos) {
                mime_to_ext.set ("video/" + video, video);
            }
            mime_to_ext.set ("video/x-matroska", "mkv");

            // audios
            mime_to_ext.set ("audio/x-wav", "wav");
            mime_to_ext.set ("audio/x-matroska", "mka");

            // images
            string[] images = {"jpeg", "png"};

            foreach (string image in images) {
                mime_to_ext.set ("image/" + image, image);
            }

            // texts
            mime_to_ext.set ("text/srt", "srt");
            mime_to_ext.set ("text/xml", "xml");

            // applications? (can be either video or audio?);
            mime_to_ext.set ("application/ogg", "ogg");
        }

        if (HTTPItemURI.mime_to_ext.has_key (mime_type)) {
            return mime_to_ext.get (mime_type);
        }

        return "";
    }
}
