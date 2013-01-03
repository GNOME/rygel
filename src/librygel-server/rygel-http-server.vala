/*
 * Copyright (C) 2008, 2009 Nokia Corporation.
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

internal class Rygel.HTTPServer : Rygel.TranscodeManager, Rygel.StateMachine {
    public string path_root { get; private set; }

    // Reference to root container of associated ContentDirectory
    public MediaContainer root_container;
    public GUPnP.Context context;
    private ArrayList<HTTPRequest> requests;

    public Cancellable cancellable { get; set; }

    public HTTPServer (ContentDirectory content_dir,
                       string           name) {
        base ();

        this.root_container = content_dir.root_container;
        this.context = content_dir.context;
        this.requests = new ArrayList<HTTPRequest> ();
        this.cancellable = content_dir.cancellable;

        this.path_root = "/" + name;
    }

    public async void run () {
        context.server.add_handler (this.path_root, this.server_handler);
        context.server.request_aborted.connect (this.on_request_aborted);
        context.server.request_started.connect (this.on_request_started);

        if (this.cancellable != null) {
            this.cancellable.cancelled.connect (this.on_cancelled);
        }
    }

    internal void add_proxy_resource (DIDLLiteItem didl_item,
                                      MediaItem    item)
                                      throws Error {
        if (this.http_uri_present (item)) {
            return;
        }

        var uri = this.create_uri_for_item (item, -1, -1, null, null);

        item.add_resource (didl_item, uri, this.get_protocol (), uri);
    }

    public bool need_proxy (string uri) {
        return Uri.parse_scheme (uri) != "http";
    }

    private bool http_uri_present (MediaItem item) {
        bool present = false;

        foreach (var uri in item.uris) {
            if (!this.need_proxy (uri)) {
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

    internal override string create_uri_for_item (MediaItem item,
                                                  int       thumbnail_index,
                                                  int       subtitle_index,
                                                  string?   transcode_target,
                                                  string?   playlist_target) {
        var uri = new HTTPItemURI (item,
                                   this,
                                   thumbnail_index,
                                   subtitle_index,
                                   transcode_target,
                                   playlist_target);

        return uri.to_string ();
    }

    internal override string get_protocol () {
        return "http-get";
    }

    internal override ArrayList<ProtocolInfo> get_protocol_info () {
        var protocol_infos = base.get_protocol_info ();

        var protocol_info = new ProtocolInfo ();
        protocol_info.protocol = this.get_protocol ();
        protocol_info.mime_type = "*";

        protocol_infos.add (protocol_info);

        return protocol_infos;
    }

    private void on_request_completed (StateMachine machine) {
        var request = machine as HTTPRequest;

        this.requests.remove (request);

        debug ("HTTP %s request for URI '%s' handled.",
               request.msg.method,
               request.msg.get_uri ().to_string (false));
    }

    private void server_handler (Soup.Server               server,
                                 Soup.Message              msg,
                                 string                    server_path,
                                 HashTable<string,string>? query,
                                 Soup.ClientContext        soup_client) {
        if (msg.method == "POST") {
            // Already handled
            return;
        }

        debug ("HTTP %s request for URI '%s'. Headers:",
               msg.method,
               msg.get_uri ().to_string (false));
        msg.request_headers.foreach ((name, value) => {
                debug ("%s : %s", name, value);
        });

        this.queue_request (new HTTPGet (this, server, msg));
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.Message       message,
                                     Soup.ClientContext client) {
        foreach (var request in this.requests) {
            if (request.msg == message) {
                request.cancellable.cancel ();
                debug ("HTTP client aborted %s request for URI '%s'.",
                       request.msg.method,
                       request.msg.get_uri ().to_string (false));

                break;
            }
        }
    }

    private void on_request_started (Soup.Server        server,
                                     Soup.Message       message,
                                     Soup.ClientContext client) {
        message.got_headers.connect (this.on_got_headers);
    }

    private void on_got_headers (Soup.Message msg) {
        if (msg.method == "POST" &&
            msg.uri.path.has_prefix (this.path_root)) {
            debug ("HTTP POST request for URI '%s'",
                   msg.get_uri ().to_string (false));

            this.queue_request (new HTTPPost (this, this.context.server, msg));
        }
    }

    private void queue_request (HTTPRequest request) {
        request.completed.connect (this.on_request_completed);
        this.requests.add (request);
        request.run.begin ();
    }
}
