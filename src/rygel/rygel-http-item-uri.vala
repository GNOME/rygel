/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.HTTPItemURI : Object {
    public string item_id;
    public int thumbnail_index;
    public string? transcode_target;
    public HTTPServer http_server;

    public HTTPItemURI (string     item_id,
                        HTTPServer http_server,
                        int        thumbnail_index = -1,
                        string?    transcode_target = null) {
        this.item_id = item_id;
        this.thumbnail_index = thumbnail_index;
        this.transcode_target = transcode_target;
        this.http_server = http_server;
    }

    public HTTPItemURI.from_string (string     uri,
                                    HTTPServer http_server)
                                    throws HTTPRequestError {
        // do not decode the path here as it may contain encoded slashes
        this.thumbnail_index = -1;
        this.transcode_target = null;
        this.http_server = http_server;

        var request_uri = uri.replace (http_server.path_root, "");
        var parts = request_uri.split ("/");

        if (parts.length < 2 || parts.length % 2 == 0) {
            throw new HTTPRequestError.BAD_REQUEST ("Invalid URI '%s'",
                                                    request_uri);
        }

        for (int i = 1; i < parts.length - 1; i += 2) {
            switch (parts[i]) {
                case "item":
                    var data = Base64.decode (Soup.URI.decode (parts[i + 1]));
                    StringBuilder builder = new StringBuilder ();
                    builder.append ((string) data);
                    this.item_id = builder.str;

                    break;
                case "transcoded":
                    this.transcode_target = Soup.URI.decode (parts[i + 1]);

                    break;
                case "thumbnail":
                    this.thumbnail_index = parts[i + 1].to_int ();

                    break;
                default:
                    break;
            }
        }

        if (this.item_id == null) {
            throw new HTTPRequestError.NOT_FOUND ("Not Found");
        }
    }

    public string to_string() {
        // there seems to be a problem converting strings properly to arrays
        // you need to call to_utf8() and assign it to a variable to make it
        // work properly
        var data = this.item_id.to_utf8 ();
        var escaped = Uri.escape_string (Base64.encode ((uchar[]) data),
                                         "",
                                         true);
        string path = "/item/" + escaped;

        if (this.transcode_target != null) {
            escaped = Uri.escape_string (this.transcode_target, "", true);
            path += "/transcoded/" + escaped;
        } else if (this.thumbnail_index >= 0) {
            path += "/thumbnail/" + this.thumbnail_index.to_string ();
        }

        return this.create_uri_for_path (path);
    }

    private string create_uri_for_path (string path) {
        return "http://%s:%u%s%s".printf (this.http_server.context.host_ip,
                                          this.http_server.context.port,
                                          this.http_server.path_root,
                                          path);
    }
}
