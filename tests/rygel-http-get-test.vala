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
    public static ClientHacks create_for_headers (MessageHeaders headers) throws Error {
        throw new ClientHacksError.NA ("");
    }

    public bool is_album_art_request (Message message) {
        return false;
    }
}

public class Rygel.HTTPGetTest : GLib.Object {
    protected HTTPServer server;
    protected HTTPClient client;

    private bool server_done;
    private bool client_done;

    private MainLoop main_loop;

    private Error error;

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

        return 0;
    }

    public HTTPGetTest () throws Error {
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
        return new HTTPGet (this.server,
                            this.server.context.server,
                            msg);
    }

    private void on_client_completed (StateMachine client) {
        if (this.server_done) {
            this.main_loop.quit ();
        }

        this.client_done = true;
    }

    private void on_message_received (HTTPServer   server,
                                      Soup.Message msg) {
        this.handle_client_message.begin (msg);
    }

    private async void handle_client_message (Soup.Message msg) {
        try {
            var request = this.create_request (msg);

            yield request.run ();

            assert ((request as HTTPGet).item != null);

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
        return new Transcoder ();
    }
}

public class Rygel.HTTPClient : GLib.Object, StateMachine {
    public GUPnP.Context context;
    public Soup.Message msg;

    public Cancellable cancellable { get; set; }

    public HTTPClient (GUPnP.Context context,
                       string        uri) {
        this.context = context;

        this.msg = new Soup.Message ("GET",  uri);
        assert (this.msg != null);
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
    public const string ITEM_ID = "TestItem";

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
            return new VideoItem ();
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
}

internal class Rygel.HTTPTranscodeHandler : Rygel.HTTPGetHandler {
    public HTTPTranscodeHandler (Transcoder  transcoder,
                                 Cancellable cancellable) {}
}

internal class Rygel.HTTPIdentityHandler : Rygel.HTTPGetHandler {
    public HTTPIdentityHandler (Cancellable cancellable) {}
}

public abstract class Rygel.MediaItem : Rygel.MediaObject {
    public long size = 1024;
    public ArrayList<Subtitle> subtitles = new ArrayList<Subtitle> ();
    public ArrayList<Thumbnail> thumbnails = new ArrayList<Thumbnail> ();

    public bool place_holder = false;

    public bool is_live_stream () {
        return true;
    }

    public bool streamable () {
        return true;
    }
}

private class Rygel.AudioItem : MediaItem {
    public int64 duration = 2048;
}

private interface Rygel.VisualItem : MediaItem {
    public abstract int width { get; set; }
    public abstract int height { get; set; }
    public abstract int pixel_width { get; set; }
    public abstract int pixel_height { get; set; }
    public abstract int color_depth { get; set; }

    public abstract ArrayList<Thumbnail> thumbnails { get; protected set; }
}

private class Rygel.VideoItem : AudioItem, VisualItem {
    public int width { get; set; default = -1; }
    public int height { get; set; default = -1; }
    public int pixel_width { get; set; default = -1; }
    public int pixel_height { get; set; default = -1; }
    public int color_depth { get; set; default = -1; }

    public ArrayList<Thumbnail> thumbnails { get; protected set; }
    public ArrayList<Subtitle> subtitles;
}

private class Rygel.MusicItem : AudioItem {
    public Thumbnail album_art;
}

public class Rygel.Thumbnail {
    public long size = 1024;
}

public class Rygel.Subtitle {
    public long size = 1024;
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

        this.msg.set_status (Soup.KnownStatusCode.OK);
        this.server.unpause_message (msg);

        this.completed ();
    }
}

public class Rygel.MediaObject {
    public string id;
}

public class Rygel.Transcoder {}
