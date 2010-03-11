/*
 * Copyright (C) 2010 Nokia Corporation.
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

using Soup;

public errordomain Rygel.TestError {
    SKIP = 77,
    TIMEOUT
}

public class Rygel.HTTPResponseTest : GLib.Object {
    private HTTPServer server;
    private HTTPClient client;

    private MainLoop main_loop;

    public static int main (string[] args) {
        try {
            var test = new HTTPResponseTest ();

            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    private HTTPResponseTest () throws TestError {
        this.server = new HTTPServer ();
        this.client = new HTTPClient (this.server.context);
        this.main_loop = new MainLoop (null, false);
    }

    private void run () throws Error {
        Error error = null;

        Timeout.add_seconds (3, () => {
            error = new TestError.TIMEOUT ("Timeout");
            this.main_loop.quit ();

            return false;
        });

        this.server.message_received.connect (this.on_message_received);

        this.client.run.begin (this.server.uri);

        this.main_loop.run ();

        if (error != null) {
            throw error;
        }
    }

    private void on_message_received (HTTPServer server,
                                      Message    msg) {
        var response = new HTTPDummyResponse (this.server.context.server,
                                              msg,
                                              false,
                                              null);

        response.completed.connect (() => {
            this.main_loop.quit ();
        });

        response.run.begin ();
    }
}

private class Rygel.HTTPDummyResponse : Rygel.HTTPResponse {
    public static const string RESPONSE_DATA = "THIS IS VALA!";

    public HTTPDummyResponse (Soup.Server  server,
                              Soup.Message msg,
                              bool         partial,
                              Cancellable? cancellable) {
        base (server, msg, partial, cancellable);
    }

    public override async void run () {
        this.server.pause_message (this.msg);

        SourceFunc run_continue = run.callback;

        Idle.add (() => {
            run_continue ();

            return false;
        });

        yield;

        this.push_data (RESPONSE_DATA, RESPONSE_DATA.length);

        this.end (false, Soup.KnownStatusCode.NONE);
    }
}

private class Rygel.HTTPServer : GLib.Object {
    private const string SERVER_PATH = "/RygelHTTPServer/Rygel/Test";

    public GUPnP.Context context;

    public string uri {
        owned get { return "http://" +
                           this.context.host_ip + ":" +
                           this.context.port.to_string () +
                           SERVER_PATH;
        }
    }

    public signal void message_received (Message message);

    public HTTPServer () throws TestError {
        try {
            this.context = new GUPnP.Context (null, "lo", 0);
        } catch (Error error) {
            throw new TestError.SKIP ("Network context not available");
        }

        assert (this.context != null);
        assert (this.context.host_ip != null);
        assert (this.context.port > 0);

        this.context.server.add_handler (SERVER_PATH, this.server_cb);
    }

    private void server_cb (Server        server,
                            Message       msg,
                            string        path,
                            HashTable?    query,
                            ClientContext client) {
        this.message_received (msg);
    }
}

private class Rygel.HTTPClient : GLib.Object {
    public GUPnP.Context context;

    public HTTPClient (GUPnP.Context context) {
        this.context = context;
    }

    public async void run (string uri) {
        var msg = new Message ("HTTP",  uri);
        assert (msg != null);

        SourceFunc run_continue = run.callback;

        this.context.session.queue_message (msg, (m) => {
            assert (msg.response_body.length ==
                    HTTPDummyResponse.RESPONSE_DATA.length);
            assert ((string) msg.response_body ==
                    HTTPDummyResponse.RESPONSE_DATA);

            run_continue ();
        });

        yield;
    }
}
