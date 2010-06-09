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
using Gee;

public errordomain Rygel.TestError {
    SKIP = 77,
    TIMEOUT
}

public class Rygel.HTTPPostTest : GLib.Object {
    protected HTTPServer server;
    protected HTTPClient client;

    private bool server_done;
    private bool client_done;

    private MainLoop main_loop;

    private Error error;

    public static int main (string[] args) {
        try {
            var test = new HTTPPostTest ();

            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    public HTTPPostTest () throws Error {
        this.server = new HTTPServer ();
        this.client = new HTTPClient (this.server.context,
                                      this.server.uri);
        this.main_loop = new MainLoop (null, false);
    }

    public virtual void run () throws Error {
        Timeout.add_seconds (3, this.on_timeout);
        this.server.message_received.connect (this.on_message_received);
        this.client.completed.connect (this.on_client_completed);

        this.client.run.begin ();

        this.main_loop.run ();

        if (this.error != null) {
            throw this.error;
        }
    }

    private HTTPRequest create_request (Soup.Message msg) throws Error {
        return new HTTPPost (this.server,
                            this.server.context.server,
                            msg);
    }

    private void on_client_completed (StateMachine client) {
        this.client_done = true;
        this.check_and_exit.begin ();
    }

    private void on_message_received (HTTPServer   server,
                                      Soup.Message msg) {
        this.handle_client_message.begin (msg);
    }

    private async void handle_client_message (Soup.Message msg) {
        try {
            var request = this.create_request (msg);

            yield request.run ();

            assert ((request as HTTPPost).item != null);

            this.server_done = true;
            this.check_and_exit.begin ();
        } catch (Error error) {
            this.error = error;
            this.main_loop.quit ();

            return;
        }
    }

    private bool on_timeout () {
        this.error = new TestError.TIMEOUT ("Timeout");
        this.main_loop.quit ();

        return false;
    }

    private async void check_and_exit () {
        if (!(this.server_done && this.client_done)) {
            return;
        }

        try {
            var file = this.server.root_container.item.file;
            var stream = yield file.read_async (Priority.HIGH, null);
            var buffer = new char[HTTPClient.LENGTH];

            yield stream.read_async (buffer,
                                     HTTPClient.LENGTH,
                                     Priority.HIGH,
                                     null);
            for (var i = 0; i < HTTPClient.LENGTH; i++) {
                assert (buffer[i] == this.client.content[i]);
            }
        } catch (Error error) {
            this.error = error;
        }

        this.main_loop.quit ();
    }
}

public class Rygel.HTTPServer : GLib.Object {
    private const string SERVER_PATH = "/RygelHTTPServer/Rygel/Test";
    public string path_root {
        get {
            return SERVER_PATH;
        }
    }

    public MediaContainer root_container;
    public GUPnP.Context context;

    public string uri {
        owned get {
            var item_uri = new HTTPItemURI (this.root_container.ITEM_ID,
                                            this);

            return item_uri.to_string ();
        }
    }

    public signal void message_received (Soup.Message message);

    public HTTPServer () throws TestError {
        try {
            this.context = new GUPnP.Context (null, "lo", 0);
        } catch (Error error) {
            throw new TestError.SKIP ("Network context not available");
        }

        assert (this.context != null);
        assert (this.context.host_ip != null);
        assert (this.context.port > 0);

        context.server.request_started.connect (this.on_request_started);

        this.root_container = new MediaContainer ();
    }

    private void on_request_started (Soup.Server        server,
                                     Soup.Message       msg,
                                     Soup.ClientContext client) {
        msg.got_headers.connect (this.on_got_headers);
    }

    private void on_got_headers (Soup.Message msg) {
        this.message_received (msg);
    }
}

public class Rygel.HTTPClient : GLib.Object, StateMachine {
    public const size_t LENGTH = 1024;

    public char[] content;

    public GUPnP.Context context;
    public Soup.Message msg;

    public Cancellable cancellable { get; set; }

    public HTTPClient (GUPnP.Context context,
                       string        uri) {
        this.context = context;
        this.content = new char[1024];

        this.msg = new Soup.Message ("POST",  uri);
        assert (this.msg != null);
    }

    public async void run () {
        SourceFunc run_continue = run.callback;

        this.msg.request_body.append (MemoryUse.COPY, content, LENGTH);

        this.context.session.queue_message (this.msg, (session, msg) => {
            run_continue ();
        });

        yield;

        this.completed ();
    }
}

public class Rygel.MediaContainer : Rygel.MediaObject {
    public const string ITEM_ID = "TestItem";

    public MediaItem item;

    public MediaContainer () {
        this.item = new MediaItem (ITEM_ID);
    }

    public async MediaObject? find_object (string       item_id,
                                           Cancellable? cancellable)
                                           throws Error {
        SourceFunc find_object_continue = find_object.callback;
        Idle.add (() => {
            find_object_continue ();

            return false;
        });

        yield;

        if (item_id == ITEM_ID) {
            return this.item;
        } else {
            return null;
        }
    }
}

public class Rygel.MediaItem : Rygel.MediaObject {
    public const string URI = "file:///tmp/rygel-upload-test.wav";

    public string id;
    public long size = 1024;
    public long duration = 1024;

    public File file;

    public MediaItem (string id) {
        this.id = id;

        this.file = File.new_for_uri (URI);
        try {
            this.file.replace (null, false, 0, null);
        } catch (IOError.EXISTS error) {
        } catch (GLib.Error error) {
            assert_not_reached ();
        }
    }

    ~MediaItem() {
        try {
            this.file.delete (null);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }
    }

    public async File? get_writable (Cancellable? cancellable) throws Error {
        SourceFunc get_writable_continue = get_writable.callback;

        Idle.add (() => {
            get_writable_continue ();

            return false;
        });

        yield;

        return this.file;
    }
}

internal class Rygel.HTTPResponse : Rygel.StateMachine, GLib.Object {
    public abstract Cancellable cancellable { get; set; }

    private Soup.Message msg;
    private Soup.Server server;

    public HTTPResponse (HTTPPost get_request) {
        this.msg = get_request.msg;
        this.server = get_request.server;
    }

    public async void run () {
        SourceFunc run_continue = run.callback;

        Idle.add (() => {
            run_continue ();

            return false;
        });

        yield;

        this.msg.set_status (Soup.KnownStatusCode.OK);
        this.server.unpause_message (msg);

        this.completed ();
    }
}

public class Rygel.MediaObject {}
