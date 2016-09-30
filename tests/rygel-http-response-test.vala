/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Soup;

public errordomain Rygel.TestError {
    SKIP = 77,
    TIMEOUT
}

public errordomain Rygel.HTTPRequestError {
    NOT_FOUND = Soup.Status.NOT_FOUND
}

public class Rygel.HTTPResponseTest : GLib.Object {
    public const long MAX_BYTES = 102400;

    protected HTTPServer server;
    protected HTTPClient client;

    private bool server_done;
    private bool client_done;

    private MediaItem item;

    private MainLoop main_loop;

    protected Cancellable cancellable;
    private Error error;

    public static int main (string[] args) {
        try {
            var test = new HTTPResponseTest.complete ();
            test.run ();

            test = new HTTPResponseTest.abort ();
            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

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

        this.item = new MediaItem.fixed_size ();
    }

    public HTTPResponseTest.abort () throws Error {
        this (new Cancellable ());

        this.item = new MediaItem ();
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

    private HTTPResponse create_response (Soup.Message msg) throws Error {
        var seek = null as HTTPSeek;

        if (!this.item.is_live_stream ()) {
            seek = new HTTPByteSeek (0, MAX_BYTES - 1, this.item.size);
            msg.response_headers.set_content_length (seek.length);
        }

        var request = new HTTPGet (this.server.context.server,
                                   msg,
                                   this.item,
                                   seek,
                                   this.cancellable);
        var handler = new HTTPGetHandler (this.cancellable);
        var src = this.item.create_stream_source ();

        return new HTTPResponse (request, handler, src);
    }

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
            this.cancellable.cancelled.connect (this.on_cancelled);
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
                                             Status.CANCELLED);
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

public class Rygel.HTTPByteSeek : Rygel.HTTPSeek {
    public HTTPByteSeek (int64 start, int64 stop, int64 total_length) {
        base (start, stop, total_length);
    }
}

public class Rygel.HTTPTimeSeek : Rygel.HTTPSeek {
    public HTTPTimeSeek (int64 start, int64 stop, int64 total_length) {
        base (start, stop, total_length);
    }
}

public class Rygel.HTTPGet : GLib.Object {
    public Soup.Server server;
    public Soup.Message msg;

    public Cancellable cancellable;

    public MediaItem item;

    internal HTTPSeek seek;

    public HTTPGet (Soup.Server  server,
                    Soup.Message msg,
                    MediaItem    item,
                    HTTPSeek?    seek,
                    Cancellable? cancellable) {
        this.server = server;
        this.msg = msg;
        this.item = item;
        this.seek = seek;
        this.cancellable = cancellable;
        this.msg.response_headers.set_encoding (Soup.Encoding.EOF);
        this.msg.set_status (Soup.Status.OK);
    }
}

public class Rygel.HTTPGetHandler : GLib.Object {
    public Cancellable cancellable;

    public HTTPGetHandler (Cancellable? cancellable) {
        this.cancellable = cancellable;
    }
}

internal class Rygel.TestDataSource : Rygel.DataSource, Object {
    private long block_size;
    private long buffers;
    private uint64 data_sent;
    private bool frozen;

    public TestDataSource (long block_size, long buffers) {
        this.block_size = block_size;
        this.buffers = buffers;
        this.data_sent = 0;
    }

    public void start (HTTPSeek? seek) throws Error {
        Idle.add ( () => {
            if (frozen) {
                return false;
            }

            var data = new uint8[block_size];
            this.data_sent += block_size;
            if (this.data_sent > HTTPResponseTest.MAX_BYTES) {
                this.done ();

                return false;
            }

            this.data_available (data);

            return true;
        });
    }

    public void freeze () {
        this.frozen = true;
    }

    public void thaw () {
        if (!this.frozen) {
            return;
        }

        this.frozen = false;

        try {
            this.start (null);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }
    }

    public void stop () {
        this.freeze ();
    }
}

public class Rygel.MediaItem {
    private const long BLOCK_SIZE = HTTPResponseTest.MAX_BYTES / 16;
    private const long MAX_BUFFERS = 25;

    public int64 size {
        get {
            return MAX_BUFFERS * BLOCK_SIZE;
        }
    }

    private DataSource src;
    bool is_live = false;

    public MediaItem () {
        this.src = new TestDataSource (BLOCK_SIZE, MAX_BUFFERS);
        this.is_live = true;
    }

    public MediaItem.fixed_size () {
        this ();
    }

    public DataSource? create_stream_source () {
        return this.src;
    }

    public bool is_live_stream () {
        return this.is_live;
    }
}
