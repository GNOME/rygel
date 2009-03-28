/*
 * Copyright (C) 2008, 2009 Nokia Corporation, all rights reserved.
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
using Gst;
using GUPnP;
using Gee;

internal class Rygel.HTTPServer : Rygel.TranscodeManager, Rygel.StateMachine {
    private const string SERVER_PATH_PREFIX = "/RygelHTTPServer";
    private string path_root;

    // Reference to root container of associated ContentDirectory
    public MediaContainer root_container;
    private GUPnP.Context context;
    private ArrayList<HTTPRequest> requests;

    private Cancellable cancellable;

    public HTTPServer (ContentDirectory content_dir,
                       string           name) {
        base ();

        this.root_container = content_dir.root_container;
        this.context = content_dir.context;
        this.requests = new ArrayList<HTTPRequest> ();

        this.path_root = SERVER_PATH_PREFIX + "/" + name;
    }

    public void run (Cancellable? cancellable) {
        context.server.add_handler (this.path_root, server_handler);

        if (cancellable != null) {
            this.cancellable = cancellable;
            this.cancellable.cancelled += this.on_cancelled;
        }
    }

    /* We prepend these resources into the original resource list instead of
     * appending them because some crappy MediaRenderer/ControlPoint
     * implemenation out there just choose the first one in the list instead of
     * the one they can handle.
     */
    internal override void add_resources (
                                ArrayList<DIDLLiteResource?> resources,
                                MediaItem                    item)
                                throws Error {
        // Create the HTTP proxy URI
        string protocol;
        var uri = this.create_uri_for_item (item, null, out protocol);
        DIDLLiteResource res = item.create_res (uri);
        res.protocol = protocol;

        if (!http_res_present (resources)) {
            resources.insert (0, res);
        }

        base.add_resources (resources, item);
    }

    private bool http_res_present (ArrayList<DIDLLiteResource?> res_list) {
        bool present = false;

        foreach (var res in res_list) {
            if (res.protocol == "http-get") {
                present = true;

                break;
            }
        }

        return present;
    }

    private void on_cancelled (Cancellable cancellable) {
        // Cancel all state machines
        this.cancellable.cancel ();

        context.server.remove_handler (this.path_root);

        this.completed ();
    }

    private string create_uri_for_path (string path) {
        return "http://%s:%u%s%s".printf (this.context.host_ip,
                                          this.context.port,
                                          this.path_root,
                                          path);
    }

    internal override string create_uri_for_item (MediaItem  item,
                                                  string?    transcode_target,
                                                  out string protocol) {
        string escaped = Uri.escape_string (item.id, "", true);
        string query = "?itemid=" + escaped;
        if (transcode_target != null) {
            escaped = Uri.escape_string (transcode_target, "", true);
            query += "&transcode=" + escaped;
        }

        protocol = "http-get";

        return create_uri_for_path (query);
    }

    private void on_request_completed (HTTPRequest request) {
        /* Remove the request from our list. */
        this.requests.remove (request);
    }

    private void server_handler (Soup.Server               server,
                                 Soup.Message              msg,
                                 string                    server_path,
                                 HashTable<string,string>? query,
                                 Soup.ClientContext        soup_client) {
        debug ("HTTP %s request for URI: %s",
               msg.method,
               msg.get_uri ().to_string (false));

        var request = new HTTPRequest (this, server, msg, query);

        request.completed += this.on_request_completed;
        this.requests.add (request);

        request.run (this.cancellable);
    }
}

