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

// This module contains the common code between the test cases for
// HTTPResponse subclasses.
using Soup;

public errordomain Rygel.TestError {
    SKIP = 77,
    TIMEOUT
}

public abstract class Rygel.HTTPResponseTest : GLib.Object {
    public const long MAX_BYTES = 102400;

    protected HTTPServer server;
    protected HTTPClient client;

    private bool server_done;
    private bool client_done;

    private MainLoop main_loop;

    protected Cancellable cancellable;
    private Error error;

    public HTTPResponseTest (Cancellable? cancellable = null) throws Error {
        this.cancellable = cancellable;

        this.server = new HTTPServer ();
        this.client = new HTTPClient (this.server.context,
                                      this.server.uri,
                                      MAX_BYTES,
                                      cancellable != null);
        this.main_loop = new MainLoop (null, false);
    }

    public HTTPResponseTest.complete () throws Error {
        this ();
    }

    public HTTPResponseTest.abort () throws Error {
        this (new Cancellable ());
    }

    public virtual void run () throws Error {
        Timeout.add_seconds (3, this.on_timeout);
        this.server.message_received.connect (this.on_message_received);
        this.server.message_aborted.connect (this.on_message_aborted);
        if (this.cancellable == null) {
            this.client.completed.connect (this.on_client_completed);
        } else {
            this.client_done = true;
        }

        this.client.run.begin ();

        this.main_loop.run ();

        if (this.error != null) {
            throw this.error;
        }
    }

    internal abstract HTTPResponse create_response (Soup.Message msg)
                                                    throws Error;

    private void on_client_completed (StateMachine client) {
        if (this.server_done) {
            this.main_loop.quit ();
        }

        this.client_done = true;
    }

    private void on_response_completed (StateMachine response) {
        if (this.client_done) {
            this.main_loop.quit ();
        }

        this.server_done = true;
    }

    private void on_message_received (HTTPServer   server,
                                      Soup.Message msg) {
        try {
            var response = this.create_response (msg);

            response.run.begin ();

            response.completed.connect (this.on_response_completed);
        } catch (Error error) {
            this.error = error;
            this.main_loop.quit ();

            return;
        }
    }

    private void on_message_aborted (HTTPServer   server,
                                     Soup.Message msg) {
        this.cancellable.cancel ();
    }

    private bool on_timeout () {
        this.error = new TestError.TIMEOUT ("Timeout");
        this.main_loop.quit ();

        return false;
    }
}

public class Rygel.HTTPServer : GLib.Object {
    private const string SERVER_PATH = "/RygelHTTPServer/Rygel/Test";

    public GUPnP.Context context;

    public string uri {
        owned get { return "http://" +
                           this.context.host_ip + ":" +
                           this.context.port.to_string () +
                           SERVER_PATH;
        }
    }

    public signal void message_received (Soup.Message message);
    public signal void message_aborted (Soup.Message message);

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
        this.context.server.request_aborted.connect (this.on_request_aborted);
    }

    private void server_cb (Server        server,
                            Soup.Message  msg,
                            string        path,
                            HashTable?    query,
                            ClientContext client) {
        this.context.server.pause_message (msg);
        this.message_received (msg);
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.Message       message,
                                     Soup.ClientContext client) {
        this.message_aborted (message);
    }
}

public class Rygel.HTTPClient : GLib.Object, StateMachine {
    public GUPnP.Context context;
    public Soup.Message msg;
    public size_t total_bytes;

    public Cancellable cancellable { get; set; }

    public HTTPClient (GUPnP.Context context,
                       string        uri,
                       size_t        total_bytes,
                       bool          active) {
        this.context = context;
        this.total_bytes = total_bytes;

        this.msg = new Soup.Message ("HTTP",  uri);
        assert (this.msg != null);
        this.msg.response_body.set_accumulate (false);

        if (active) {
            this.cancellable = new Cancellable ();
            this.cancellable.cancelled += this.on_cancelled;
        }
    }

    public async void run () {
        SourceFunc run_continue = run.callback;
        size_t bytes_received = 0;

        this.msg.got_chunk.connect ((msg, chunk) => {
            bytes_received += chunk.length;

            if (bytes_received >= this.total_bytes &&
                this.cancellable != null) {

                this.cancellable.cancel ();
            }
        });

        this.context.session.queue_message (this.msg, (session, msg) => {
            assert (cancellable != null || bytes_received == this.total_bytes);

            run_continue ();
        });

        yield;

        this.completed ();
    }

    private void on_cancelled (Cancellable cancellable) {
        this.context.session.cancel_message (this.msg,
                                             KnownStatusCode.CANCELLED);
        this.completed ();
    }
}

public class Rygel.HTTPSeek : GLib.Object {
    public int64 start { get; private set; }
    public int64 stop { get; private set; }
    public int64 length { get; private set; }
    public int64 total_length { get; private set; }

    public HTTPSeek (int64 start, int64 stop, int64 total_length) {
        this.start = start;
        this.stop = stop;
        this.total_length = total_length;

        this.length = stop - start + 1;
    }
}
