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

public class Rygel.HTTPServer : GLib.Object, Rygel.StateMachine {
    private const string SERVER_PATH_PREFIX = "/RygelHTTPServer";
    private string path_root;

    // Reference to root container of associated ContentDirectory
    private MediaContainer root_container;
    private GUPnP.Context context;
    private ArrayList<HTTPRequest> requests;

    private Cancellable cancellable;

    public HTTPServer (ContentDirectory content_dir,
                       string           name) {
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

    public ArrayList<DIDLLiteResource?>? create_resources
                                (MediaItem                    item,
                                 ArrayList<DIDLLiteResource?> orig_res_list)
                                 throws Error {
        var resources = new ArrayList<DIDLLiteResource?> ();

        if (http_res_present (orig_res_list)) {
            return resources;
        }

        // Create the HTTP proxy URI
        var uri = this.create_http_uri_for_item (item, false);
        DIDLLiteResource res = item.create_res (uri);
        res.protocol = "http-get";
        resources.add (res);

        // Create the HTTP transcode URI
        uri = this.create_http_uri_for_item (item, true);
        res = item.create_res (uri);
        res.protocol = "http-get";
        resources.add (res);

        return resources;
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

    private string create_http_uri_for_item (MediaItem item, bool transcode) {
        string escaped = Uri.escape_string (item.id, "", true);
        string query = "?itemid=%s&transcode=%s".printf (
                                escaped,
                                transcode.to_string ());

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
        var request = new HTTPRequest (this.root_container, server, msg, query);

        request.completed += this.on_request_completed;
        this.requests.add (request);

        request.run (this.cancellable);
    }
}

