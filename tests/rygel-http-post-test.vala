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

public errordomain Rygel.ClientHacksError {
    NA
}

public class Rygel.ClientHacks {
    public static ClientHacks create (Message? message) throws Error {
        throw new ClientHacksError.NA ("");
    }

    public void apply (MediaFileItem item) {
    }
}

public class Rygel.TestRequestFactory {
    public Soup.Message msg;
    public Soup.Status? expected_code;
    public bool cancel;

    public TestRequestFactory (Soup.Message msg,
                               Soup.Status? expected_code,
                               bool cancel = false) {
        this.msg = msg;
        this.expected_code = expected_code;
        this.cancel = cancel;
    }

    internal HTTPPost create_post (HTTPServer http_server,
                                   Soup.Server server,
                                   Soup.Message msg) {
        HTTPPost request = new HTTPPost (http_server, server, msg);

        return request;
    }
}

public class Rygel.HTTPPostTest : GLib.Object {
    protected HTTPServer server;
    protected HTTPClient client;
    private bool server_done;
    private bool client_done;
    private bool ready;

    private MainLoop main_loop;
    private Error error;

    private ArrayList<TestRequestFactory> requests;
    private TestRequestFactory current_request;

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
        this.client = new HTTPClient (this.server.context);
        this.main_loop = new MainLoop (null, false);
        this.create_test_messages();
    }

    public virtual void run () throws Error {
        // cleanup
        var file = File.new_for_uri (MediaFileItem.URI);
        FileUtils.remove (file.get_path ());

        Timeout.add_seconds (10, this.on_timeout);
        this.server.message_received.connect (this.on_message_received);
        this.client.completed.connect (this.on_client_completed);

        this.start_next_test_request ();

        this.main_loop.run ();

        if (this.error != null) {
            throw this.error;
        }
    }

    private void create_test_messages () {
        requests = new ArrayList<TestRequestFactory> ();

        var request = new Soup.Message ("POST", this.server.uri);
        requests.add (new TestRequestFactory (request, Soup.Status.OK));

        request = new Soup.Message ("POST", this.server.uri);
        requests.add (new TestRequestFactory (request,
                                             Soup.Status.NOT_FOUND));

        request = new Soup.Message ("POST", this.server.create_uri ("NullItem"));
        requests.add (new TestRequestFactory (request,
                                              Soup.Status.BAD_REQUEST));

        request = new Soup.Message ("POST",
                                    this.server.create_uri ("ErrorItem"));
        requests.add (new TestRequestFactory (request,
                                              Soup.Status.OK));

        request = new Soup.Message ("POST",
                                    this.server.create_uri ("CancelItem"));
        requests.add (new TestRequestFactory (request,
                                              Soup.Status.OK, true));

        request = new Soup.Message ("POST",
                                    this.server.create_uri ("VanishingItem"));
        requests.add (new TestRequestFactory (request, Soup.Status.OK));
    }

    private HTTPRequest create_request (Soup.Message msg) throws Error {
        var srv = this.server.context.server;
        var request = this.current_request.create_post (this.server, srv, msg);

        return request;
    }

    private void start_next_test_request() {
        this.current_request = requests.remove_at (0);
        this.client.msg = this.current_request.msg;

        this.client.run.begin ();
    }

    private void on_client_completed (StateMachine client) {
        if (requests.size > 0) {
            if (this.server_done) {
                this.server_done = false;
                this.start_next_test_request ();
            } else {
                this.ready = true;
            }
        } else {
            if (this.server_done) {
                this.main_loop.quit ();
            }
            this.client_done = true;
        }
    }

    private void on_message_received (HTTPServer   server,
                                      Soup.Message msg) {
        this.handle_client_message.begin (msg);
    }

    private async void handle_client_message (Soup.Message msg) {
        try {
            var request = this.create_request (msg);

            if (this.current_request.cancel) {
                request.cancellable.cancel ();
            } else {
                yield request.run ();

                debug ("status.code: %d", (int) msg.status_code);
                assert (msg.status_code == this.current_request.expected_code);

                this.check_result.begin ();
            }

            if (this.client_done) {
                this.main_loop.quit ();
            } else if (this.ready) {
                this.ready = false;

                start_next_test_request ();
            } else {
                this.server_done = true;
            }
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

    private async void check_result () {
        try {
            var file = this.server.root_container.item.file;
            var stream = yield file.read_async (Priority.HIGH, null);
            var buffer = new uint8[HTTPClient.LENGTH];
            yield stream.read_async (buffer, Priority.HIGH, null);

            for (var i = 0; i < HTTPClient.LENGTH; i++) {
                assert (buffer[i] == this.client.content[i]);
            }
        } catch (IOError.NOT_FOUND e) {
            return;
        } catch (Error error) {
            this.error = error;

            this.main_loop.quit ();
        }
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
			var item = new MediaFileItem (MediaContainer.ITEM_ID, this.root_container);
			var item_uri = new HTTPItemURI (item, this);
            return item_uri.to_string ();
        }
    }

    public string create_uri(string item_id) {
        var item = new MediaFileItem (item_id, this.root_container);
        var item_uri = new HTTPItemURI (item, this);
        return item_uri.to_string ();
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

    public Transcoder get_transcoder (string target) throws Error {
        if (target == "MP3") {
            return new Transcoder ("mp3");
        }
        throw new HTTPRequestError.NOT_FOUND (
                            "No transcoder available for target format '%s'",
                            target);
    }
}

public class Rygel.HTTPClient : GLib.Object, StateMachine {
    public const size_t LENGTH = 1024;

    public uint8[] content;

    public GUPnP.Context context;
    public Soup.Message msg;

    public Cancellable cancellable { get; set; }

    public HTTPClient (GUPnP.Context context) {
        this.context = context;
        this.content = new uint8[1024];
    }

    public async void run () {
        SourceFunc run_continue = run.callback;

        this.msg.request_body.append (MemoryUse.COPY, content);

        this.context.session.queue_message (this.msg, (session, msg) => {
            run_continue ();
        });

        yield;

        this.completed ();
    }
}

public class Rygel.MediaContainer : Rygel.MediaObject {
    public const string ITEM_ID = "TestItem";

    public signal void container_updated (MediaContainer container);

    public MediaFileItem item;
    private bool vanish;
    private bool error;

    public File file;
    private FileMonitor monitor;

    public MediaContainer () {
        this.file = File.new_for_uri (MediaFileItem.URI);
        this.item = new MediaFileItem (ITEM_ID, this);
        this.vanish = false;
        this.error = false;
        this.id = "TesContainer";

        try {
            this.monitor = this.file.monitor_file (FileMonitorFlags.NONE);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        this.monitor.changed.connect (this.on_file_changed);
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

        if (item_id == "ErrorItem" && this.error) {
            var msg = _("Fake error caused by %s object.");
            this.file.delete (null);

            throw new ContentDirectoryError.INVALID_ARGS (msg, item_id);
        } else if (item_id == "ErrorItem" && !this.error) {
            this.error = true;
        }

        if (item_id == "VanishingItem" && this.vanish) {
            this.file.delete (null);

            return null;
        } else if (item_id == "VanishingItem" && !this.vanish) {
            this.vanish = true;
        }

        if (item_id != this.item.id) {
            this.item = new MediaFileItem (item_id, this);
        }

        return this.item;
    }

    public void on_file_changed (FileMonitor      monitor,
                                 File             file,
                                 File?            other_file,
                                 FileMonitorEvent event_type) {
        this.item.place_holder = false;

        this.container_updated (this);
    }

    ~MediaContainer() {
        try {
            this.file.delete (null);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }
    }
}

public class Rygel.MediaFileItem : Rygel.MediaObject {
    public const string URI = "file:///tmp/rygel-upload-test.wav";

    public long size = 1024;
    public long duration = 1024;
    public ArrayList<string> uris = new ArrayList<string> ();
    public Gee.ArrayList<string> get_uris () { return this.uris; }

    public bool place_holder = true;

    public File file;

    public MediaFileItem.for_visual_item () {}

    public MediaFileItem (string id, MediaContainer parent) {
        this.id = id;
        this.parent = parent;

        this.file = parent.file;
    }

    public async File? get_writable (Cancellable? cancellable) throws Error {
        SourceFunc get_writable_continue = get_writable.callback;

        Idle.add (() => {
            get_writable_continue ();

            return false;
        });

        yield;

        if (this.id == "NullItem") {
            this.file.delete (null);

            return null;
        } else {
            return this.file;
        }
    }
}

internal class Rygel.HTTPResponse : Rygel.StateMachine, GLib.Object {
    public Cancellable cancellable { get; set; }

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

        this.msg.set_status (Soup.Status.OK);
        this.server.unpause_message (msg);

        this.completed ();
    }
}

public class Rygel.ObjectRemovalQueue: GLib.Object {
    public static ObjectRemovalQueue get_default () {
       return new ObjectRemovalQueue ();
    }

    public bool dequeue (MediaObject item) {
        return true;
    }

    public async void remove_now (MediaObject item, Cancellable? cancellable) {
        Idle.add (remove_now.callback);

        yield;
    }
}

public class Rygel.MediaObject : GLib.Object {
    public string id;
    public unowned MediaContainer parent;
    public string mime_type = "";
}

public class Rygel.Thumbnail : GLib.Object {
    public string file_extension;
}

public class Rygel.VisualItem : Rygel.MediaFileItem {
    public ArrayList<Thumbnail> thumbnails = new ArrayList<Thumbnail> ();

    public VisualItem () {
        base.for_visual_item();
    }
}

private class Rygel.Subtitle : GLib.Object {
    public string caption_type;
}

private class Rygel.VideoItem : Rygel.VisualItem {
    public ArrayList<Subtitle> subtitles = new ArrayList<Subtitle> ();
}

private class Rygel.MusicItem : MediaFileItem {
    public Thumbnail album_art;

    public MusicItem (string id, MediaContainer parent) {
        base (id, parent);
    }
}

public errordomain Rygel.ContentDirectoryError {
    INVALID_ARGS = 402
}

public class Rygel.Transcoder : GLib.Object {
    public string extension { get; protected set; }

    public Transcoder (string extension) {
        this.extension = extension;
    }
}
