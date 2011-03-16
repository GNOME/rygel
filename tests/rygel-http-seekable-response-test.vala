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

public class Rygel.HTTPSeek : GLib.Object {
    public int64 start { get; private set; }
    public int64 stop { get; private set; }
    public int64 length { get; private set; }

    public HTTPSeek (int64 start, int64 stop) {
        this.start = start;
        this.stop = stop;

        this.length = stop - start + 1;
    }
}

public class Rygel.HTTPSeekableResponseTest : Rygel.HTTPResponseTest {
    private File dummy_file;

    public static int main (string[] args) {
        try {
            var test = new HTTPSeekableResponseTest.complete ();
            test.run ();

            test = new HTTPSeekableResponseTest.abort ();
            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    private HTTPSeekableResponseTest (Cancellable? cancellable = null)
                                      throws Error {
        base (cancellable);
    }

    private HTTPSeekableResponseTest.complete () throws Error {
        base.complete ();
    }

    private HTTPSeekableResponseTest.abort () throws Error {
        base.abort ();
    }

    public override void run () throws Error {
        this.create_dummy_file ();

        base.run ();

        this.dummy_file.delete (null);
    }

    private void create_dummy_file () throws Error {
        this.dummy_file = File.new_for_uri (MediaItem.URI);
        var stream = this.dummy_file.replace (null, false, 0, null);

        // Put randon stuff into it
        stream.write (new uint8[1024], null);
    }

    internal override HTTPResponse create_response (Soup.Message msg)
                                                    throws Error {
        var seek = new HTTPSeek (0, 1024);
        var item = new MediaItem ();

        var request = new HTTPGet (this.server.context.server,
                                   msg,
                                   item,
                                   seek,
                                   this.cancellable);
        var handler = new HTTPGetHandler (this.cancellable);

        return new HTTPSeekableResponse (request, handler);
    }
}

public class Rygel.HTTPGet : GLib.Object {
    public Soup.Server server;
    public Soup.Message msg;

    public Cancellable cancellable;

    public MediaItem item;

    internal HTTPSeek seek;

    public Subtitle subtitle;
    public Thumbnail thumbnail;

    public HTTPGet (Soup.Server  server,
                    Soup.Message msg,
                    MediaItem    item,
                    HTTPSeek     seek,
                    Cancellable? cancellable) {
        this.server = server;
        this.msg = msg;
        this.item = item;
        this.seek = seek;
        this.cancellable = cancellable;
    }
}

public class Rygel.HTTPGetHandler : GLib.Object {
    public Cancellable cancellable;

    public HTTPGetHandler (Cancellable? cancellable) {
        this.cancellable = cancellable;
    }
}

public class Rygel.MediaItem {
    public const string URI = "file:///tmp/rygel-dummy-test-file";

    public string id = "Dummy";
    public Gee.ArrayList<string> uris;
    public int64 size = 1024;

    public MediaItem () {
        this.uris = new ArrayList<string> ();

        this.uris.add (URI);
    }
}

public class Rygel.Subtitle {
    public string uri;
    public int64 size = -1;   // Size in bytes
}

public class Rygel.Thumbnail {
    public string uri;

    public int64 size = -1; // Size in bytes
}

public errordomain Rygel.HTTPRequestError {
    NOT_FOUND = Soup.KnownStatusCode.NOT_FOUND
}
