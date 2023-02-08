/*
 * Copyright (C) 2008, 2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;
using Gee;

public class Rygel.HTTPServer : GLib.Object, Rygel.StateMachine {
    public string path_root { get; private set; }
    public string server_name { get; set; }

    // Reference to root container of associated ContentDirectory
    public MediaContainer root_container;
    public GUPnP.Context context;
    private ArrayList<HTTPRequest> requests;
    private bool locally_hosted;
    public HashTable<string, string> replacements;

    public Cancellable cancellable { get; set; }

    private const string SERVER_TEMPLATE = "%s/%s %s/%s DLNA/1.51 UPnP/1.0";

    public HTTPServer (ContentDirectory content_dir,
                       string           name) {
        base ();

        try {
            var config = MetaConfig.get_default ();
            this.server_name = config.get_string (name, "server-name");
        } catch (Error error) {
            this.server_name = SERVER_TEMPLATE.printf
                                        (name,
                                         BuildConfig.PACKAGE_VERSION,
                                         Environment.get_prgname (),
                                         BuildConfig.PACKAGE_VERSION);
        }

        this.root_container = content_dir.root_container;
        this.context = content_dir.context;
        this.requests = new ArrayList<HTTPRequest> ();
        this.cancellable = content_dir.cancellable;

        this.locally_hosted = this.context.get_address ().get_is_loopback ();

        this.path_root = "/" + name;
        this.replacements = new HashTable <string, string> (str_hash, str_equal);
        this.replacements.insert ("@SERVICE_ADDRESS@",
                                  this.context.address.to_string ());
        this.replacements.insert ("@ADDRESS@",
                                  this.context.address.to_string ());
        this.replacements.insert ("@SERVICE_INTERFACE@",
                                  this.context.interface);
        this.replacements.insert ("@SERVICE_PORT@",
                                  this.context.port.to_string ());
        this.replacements.insert ("@HOSTNAME@", Environment.get_host_name ());
    }

    public async void run () {
        context.add_server_handler (true, this.path_root, this.server_handler);
        context.server.request_aborted.connect (this.on_request_aborted);
        context.server.request_started.connect (this.on_request_started);
        context.server.request_read.connect (this.on_request_read);

        if (this.cancellable != null) {
            this.cancellable.cancelled.connect (this.on_cancelled);
        }
    }

    /**
     * Set or unset options the server supports/doesn't support
     *
     * Resources should be setup assuming server supports all optional
     * delivery modes
     */
    public void set_resource_delivery_options (MediaResource res) {
        res.protocol = this.get_protocol ();
        // Set this just to be safe
        res.dlna_flags |= DLNAFlags.DLNA_V15;
        // This server supports all DLNA delivery modes - so leave those flags
        // alone
     }

    public bool need_proxy (string uri) {
        return Uri.parse_scheme (uri) != "http";
    }

    private void on_cancelled (Cancellable cancellable) {
        // Cancel all state machines
        this.cancellable.cancel ();

        context.server.remove_handler (this.path_root);

        this.completed ();
    }

    internal string create_uri_for_object (MediaObject object,
                                           int         thumbnail_index,
                                           int         subtitle_index,
                                           string?     resource_name) {
        var uri = new HTTPItemURI (object,
                                   this,
                                   thumbnail_index,
                                   subtitle_index,
                                   resource_name);

        return uri.to_string ();
    }

    internal virtual string get_protocol () {
        return "http-get";
    }

    internal virtual ArrayList<ProtocolInfo> get_protocol_info () {
        return new ArrayList<ProtocolInfo>();
    }

    public HashTable<string, string> get_replacements () {
        return this.replacements;
    }

    public bool is_local () {
        return this.locally_hosted;
    }

    private void on_request_completed (StateMachine machine) {
        var request = machine as HTTPRequest;

        this.requests.remove (request);

        debug ("HTTP %s request for URI '%s' handled.",
               request.msg.get_method (),
               request.msg.get_uri ().to_string ());
    }

    private void server_handler (Soup.Server               server,
                                 Soup.ServerMessage        msg,
                                 string                    server_path,
                                 HashTable<string,string>? query) {
        if (msg.get_method () == "POST") {
            // Already handled
            return;
        }

        debug ("HTTP %s request for URI '%s'. Headers:",
               msg.get_method (),
               msg.get_uri ().to_string ());
        msg.get_request_headers ().foreach ((name, value) => {
                debug ("    %s : %s", name, value);
        });

        this.queue_request (new HTTPGet (this, server, msg));
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.ServerMessage message) {
        foreach (var request in this.requests) {
            if (request.msg == message) {
                request.cancellable.cancel ();
                debug ("HTTP client aborted %s request for URI '%s'.",
                       request.msg.get_method (),
                       request.msg.get_uri ().to_string ());

                break;
            }
        }
    }

    private void on_request_started (Soup.Server        server,
                                     Soup.ServerMessage  message) {
        message.got_headers.connect (this.on_got_headers);
    }

    private void on_request_read (Soup.Server        server,
                                  Soup.ServerMessage message) {
        var agent = message.get_request_headers ().get_one ("User-Agent");

        if (agent == null) {
            var host = message.get_remote_host ();
            agent = this.context.guess_user_agent (host);
            if (agent != null) {
                debug ("Guessed user agent %s for %s", agent, host);
                message.get_request_headers ().append ("User-Agent", agent);
            } else {
                debug ("Could not guess user agent for ip %s.", host);
            }
        }

    }

    private void on_got_headers (Soup.ServerMessage msg) {
        if (msg.get_method () == "POST" &&
            msg.get_uri ().get_path ().has_prefix (this.path_root)) {
            debug ("HTTP POST request for URI '%s'",
                   msg.get_uri ().to_string ());

            this.queue_request (new HTTPPost (this, this.context.server, msg));
        }
    }

    private void queue_request (HTTPRequest request) {
        request.completed.connect (this.on_request_completed);
        this.requests.add (request);
        request.run.begin ();
    }
}
