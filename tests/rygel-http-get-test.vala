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
        var headers = message.request_headers;
        if (headers.get_one ("clienthacks.test.rygel") != null) {
            return new ClientHacks ();
        } else {
            throw new ClientHacksError.NA ("");
        }
    }

    public void apply (MediaObject? item) {
    }

    public bool force_seek () {
        return false;
    }
}

public class Rygel.TestRequestFactory {
    public Soup.Message msg;
    public Soup.Status expected_code;

    public TestRequestFactory (Soup.Message msg,
                               Soup.Status expected_code) {
        this.msg = msg;
        this.expected_code = expected_code;
    }

    internal HTTPGet create_get (HTTPServer http_server,
                                 Soup.Server server,
                                 Soup.Message msg) {
        HTTPGet request = new HTTPGet (http_server, server, msg);
        request.handler = null;

        return request;
    }
}

public class Rygel.HTTPGetTest : GLib.Object {
    protected HTTPServer server;
    protected HTTPClient client;

    private bool server_done;
    private bool client_done;

    private MainLoop main_loop;

    private Error error;

    private ArrayList<TestRequestFactory> requests;
    private TestRequestFactory current_request;

    public static int main (string[] args) {
        try {
            var test = new HTTPGetTest ();

            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        /* Avoid some warnings about unused methods: */
        var item = new VideoItem();
        assert (!item.is_live_stream());
        assert (!item.streamable());

        return 0;
    }

    public HTTPGetTest () throws Error {
        this.server = new HTTPServer ();
        this.client = new HTTPClient (this.server.context);
        this.main_loop = new MainLoop (null, false);
        this.create_test_messages();
    }

    public virtual void run () throws Error {
        Timeout.add_seconds (3, this.on_timeout);
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

        Soup.Message request = new Soup.Message ("POST", this.server.uri);
        requests.add (new TestRequestFactory (request,
                      Soup.Status.BAD_REQUEST));

        request = new Soup.Message ("HEAD", this.server.uri);
        requests.add (new TestRequestFactory (request, Soup.Status.OK));

        request = new Soup.Message ("GET", this.server.uri);
        requests.add (new TestRequestFactory (request, Soup.Status.OK));

        string uri = this.server.create_uri ("VideoItem");
        uri = uri + "/tr/MP3";
        request = new Soup.Message ("HEAD", uri);
        requests.add (new TestRequestFactory (request, Soup.Status.OK));

        request = new Soup.Message ("GET", this.server.uri);
        request.request_headers.append ("transferMode.dlna.org", "Streaming");
        requests.add (new TestRequestFactory (request, Soup.Status.OK));

        request = new Soup.Message ("GET", this.server.uri);
        request.request_headers.append ("transferMode.dlna.org", "Interactive");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.NOT_ACCEPTABLE));

        request = new Soup.Message ("GET", this.server.uri);
        request.request_headers.append ("Range", "bytes=1-2");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.OK));

        uri = this.server.create_uri ("AudioItem");
        uri = uri + "/th/0";

        request = new Soup.Message ("GET", uri);
        requests.add (new TestRequestFactory (request,
                      Soup.Status.NOT_FOUND));

        request = new Soup.Message ("GET", this.server.uri);
        request.request_headers.append ("TimeSeekRange.dlna.org", "0");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.NOT_ACCEPTABLE));

        uri = this.server.create_uri ("AudioItem");
        request = new Soup.Message ("GET", uri);
        request.request_headers.append ("TimeSeekRange.dlna.org", "0");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.BAD_REQUEST));

        uri = this.server.create_uri ("AudioItem");
        request = new Soup.Message ("GET", uri);
        request.request_headers.append ("TimeSeekRange.dlna.org", "npt=1-2049");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.REQUESTED_RANGE_NOT_SATISFIABLE));

        request = new Soup.Message ("GET", this.server.uri);
        request.request_headers.append ("clienthacks.test.rygel", "f");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.OK));

        request = new Soup.Message ("GET", this.server.uri);
        request.request_headers.append ("clienthacks.test.rygel", "t");
        requests.add (new TestRequestFactory (request,
                      Soup.Status.OK));
    }

    private HTTPGet create_request (Soup.Message msg) throws Error {
        HTTPGet request = this.current_request.create_get (this.server,
                            this.server.context.server, msg);
        return request;
    }

    private void on_client_completed (StateMachine client) {
        if (requests.size > 0) {
            this.start_next_test_request ();
        } else {
            this.main_loop.quit ();
            this.client_done = true;
        }
    }

    private void start_next_test_request() {
        this.current_request = requests.remove_at (0);
        this.client.msg = this.current_request.msg;
        this.client.run.begin ();
    }

    private void on_message_received (HTTPServer   server,
                                      Soup.Message msg) {
        this.handle_client_message.begin (msg);
    }

    private async void handle_client_message (Soup.Message msg) {
        try {
            var request = this.create_request (msg);

            yield request.run ();

            assert ((request as HTTPGet).object != null);

            debug ("status.code: %d", (int) msg.status_code);
            assert (msg.status_code == this.current_request.expected_code);

            if (this.client_done) {
                this.main_loop.quit ();
            }

            this.server_done = true;
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
            return create_uri("VideoItem");
        }
    }

    public string create_uri (string item_id) {
        var item = new VideoItem ();
        item.id = item_id;

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

        this.context.server.add_handler (SERVER_PATH, this.server_cb);

        this.root_container = new MediaContainer ();
    }

    private void server_cb (Server        server,
                            Soup.Message  msg,
                            string        path,
                            HashTable?    query,
                            ClientContext client) {
        this.context.server.pause_message (msg);
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
    public GUPnP.Context context;
    public Soup.Message msg;

    public Cancellable cancellable { get; set; }

    public HTTPClient (GUPnP.Context context) {
        this.context = context;
    }

    public async void run () {
        SourceFunc run_continue = run.callback;

        this.context.session.queue_message (this.msg, (session, msg) => {
            run_continue ();
        });

        yield;

        this.completed ();
    }
}

public class Rygel.MediaContainer : Rygel.MediaObject {

    public async MediaObject? find_object (string       item_id,
                                           Cancellable? cancellable)
                                           throws Error {
        SourceFunc find_object_continue = find_object.callback;
        Idle.add (() => {
            find_object_continue ();

            return false;
        });

        yield;

        debug ("item id: %s", item_id);
        if (item_id == "VideoItem") {
            return new VideoItem ();
        } else if (item_id == "AudioItem") {
            return new AudioItem ();
        } else {
            return null;
        }
    }
}

internal abstract class Rygel.HTTPGetHandler {
    public HTTPResponse render_body (HTTPGet get_request) {
        return new HTTPResponse (get_request);
    }

    public void add_response_headers (HTTPGet get_request) {}

    public bool knows_size (HTTPGet request) { return false; }
}

internal class Rygel.HTTPTranscodeHandler : Rygel.HTTPGetHandler {
    public HTTPTranscodeHandler (Transcoder  transcoder,
                                 Cancellable cancellable) {}
}

internal class Rygel.HTTPIdentityHandler : Rygel.HTTPGetHandler {
    public HTTPIdentityHandler (Cancellable cancellable) {}
}

internal class Rygel.HTTPPlaylistHandler : Rygel.HTTPGetHandler {
    public HTTPPlaylistHandler (string? arg, Cancellable cancellable) {}

    public static bool is_supported (string? arg) { return true; }
}

public abstract class Rygel.MediaFileItem : Rygel.MediaObject {
    public long size = 1024;
    public ArrayList<string> uris = new ArrayList<string> ();

    public Gee.ArrayList<string> get_uris () { return this.uris; }

    public bool place_holder = false;

    public bool is_live_stream () {
        if (this.id == "VideoItem")
            return false;
        else
            return true;
    }

    public bool streamable () {
        return true;
    }
}

private class Rygel.AudioItem : MediaFileItem {
    public int64 duration = 2048;

    public AudioItem () {
        this.id = "AudioItem";
    }
}

private interface Rygel.VisualItem : MediaFileItem {
    public abstract int width { get; set; }
    public abstract int height { get; set; }
    public abstract int color_depth { get; set; }

    public abstract ArrayList<Thumbnail> thumbnails { get; protected set; }

    public bool is_live_stream () {
        return false;
    }

    public bool streamable () {
        return false;
    }
}

private class Rygel.VideoItem : AudioItem, VisualItem {
    public int width { get; set; default = -1; }
    public int height { get; set; default = -1; }
    public int color_depth { get; set; default = -1; }

    private ArrayList<Thumbnail> ts;

    public VideoItem () {
        this.id = "VideoItem";
    }

    public ArrayList<Thumbnail> thumbnails {
        get {
            this.ts = new ArrayList<Thumbnail>();
            ts.add(new Rygel.Thumbnail());
            return this.ts;
        }

        protected set {}
    }

    public ArrayList<Subtitle> subtitles = new ArrayList<Subtitle> ();
}

private class Rygel.MusicItem : AudioItem {
    public Thumbnail album_art;
}

public class Rygel.Thumbnail {
    public long size = 1024;
    public string file_extension;
}

public class Rygel.Subtitle {
    public long size = 1024;
    public string caption_type;
}

internal class Rygel.HTTPResponse : Rygel.StateMachine, GLib.Object {
    public Cancellable cancellable { get; set; }

    private Soup.Message msg;
    private Soup.Server server;

    public HTTPResponse (HTTPGet get_request) {
        this.msg = get_request.msg;
        this.msg.response_headers.set_encoding (Soup.Encoding.CONTENT_LENGTH);
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

public class Rygel.MediaObject {
    public string id;
    public string mime_type = "";
}

public class Rygel.Transcoder : GLib.Object {
    public string extension { get; protected set; }

    public Transcoder (string extension) {
        this.extension = extension;
    }
}
