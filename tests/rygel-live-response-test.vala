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
using Gst;

public errordomain Rygel.TestError {
    SKIP = 77,
    TIMEOUT
}

public class Rygel.LiveResponseTest : GLib.Object {
    private static const long MAX_BYTES = 1024;
    private static const long BLOCK_SIZE = MAX_BYTES / 16;
    private static const long MAX_BUFFERS = MAX_BYTES / BLOCK_SIZE;

    private HTTPServer server;
    private HTTPClient client;

    private MainLoop main_loop;

    private dynamic Element src;

    private Cancellable cancellable;
    private Error error;

    public static int main (string[] args) {
        Gst.init (ref args);

        try {
            var test = new LiveResponseTest.complete ();
            test.run ();

            test = new LiveResponseTest.abort ();
            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    private LiveResponseTest (Cancellable? cancellable = null) throws Error {
        this.cancellable = cancellable;

        this.server = new HTTPServer ();
        this.client = new HTTPClient (this.server.context,
                                      this.server.uri,
                                      MAX_BYTES,
                                      cancellable != null);
        this.main_loop = new MainLoop (null, false);
        this.src = GstUtils.create_element ("audiotestsrc", null);
    }

    private LiveResponseTest.complete () throws Error {
        this ();

        this.src.blocksize = BLOCK_SIZE;
        this.src.num_buffers = MAX_BUFFERS;
    }

    private LiveResponseTest.abort () throws Error {
        this (new Cancellable ());
    }

    private void run () throws Error {
        Timeout.add_seconds (3, this.on_timeout);
        this.server.message_received.connect (this.on_message_received);
        this.server.message_aborted.connect (this.on_message_aborted);
        if (this.cancellable == null) {
            this.client.completed.connect (this.on_client_completed);
        }

        this.client.run.begin ();

        this.main_loop.run ();

        if (this.error != null) {
            throw this.error;
        }
    }

    private void on_client_completed (StateMachine client) {
        this.main_loop.quit ();
    }

    private void on_message_received (HTTPServer   server,
                                      Soup.Message msg) {
        try {
            var response = new LiveResponse (server.context.server,
                                             msg,
                                             "TestingLiveResponse",
                                             this.src,
                                             null,
                                             this.cancellable);

            response.run.begin ();

            if (this.cancellable != null) {
                response.completed.connect (this.on_client_completed);
            }
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
        this.message_received (msg);
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.Message       message,
                                     Soup.ClientContext client) {
        this.message_aborted (message);
    }
}

private class Rygel.HTTPClient : GLib.Object, StateMachine {
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
                bytes_received = bytes_received.clamp (0, this.total_bytes);

                this.cancellable.cancel ();
            }
        });

        this.context.session.queue_message (this.msg, (session, msg) => {
            assert (bytes_received == this.total_bytes);

            run_continue ();
        });

        yield;

        this.completed ();
    }

    private void on_cancelled (Cancellable cancellable) {
        this.context.session.cancel_message (this.msg,
                                             KnownStatusCode.CANCELLED);
    }
}
