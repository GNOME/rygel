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

public class Rygel.HTTPGstResponseTest : Rygel.HTTPResponseTest {
    private MediaItem item;

    public static int main (string[] args) {
        Gst.init (ref args);

        try {
            var test = new HTTPGstResponseTest.complete ();
            test.run ();

            test = new HTTPGstResponseTest.abort ();
            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    private HTTPGstResponseTest.complete () throws Error {
        base.complete ();

        this.item = new MediaItem.fixed_size ();
    }

    private HTTPGstResponseTest.abort () throws Error {
        base.abort ();

        this.item = new MediaItem ();
    }

    internal override HTTPResponse create_response (Soup.Message msg)
                                                     throws Error {
        var request = new HTTPGet (this.server.context.server,
                                   msg,
                                   this.item,
                                   this.cancellable);
        var handler = new HTTPGetHandler (this.cancellable);

        return new HTTPGstResponse (request, handler);
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
                    Cancellable? cancellable) {
        this.server = server;
        this.msg = msg;
        this.item = item;
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
    private static const long BLOCK_SIZE = HTTPResponseTest.MAX_BYTES / 16;
    private static const long MAX_BUFFERS =
                                        HTTPResponseTest.MAX_BYTES / BLOCK_SIZE;

    private dynamic Element src;

    public MediaItem () {
        this.src = GstUtils.create_element ("fakesrc", null);
        this.src.sizetype = 2; // fixed
    }

    public MediaItem.fixed_size () {
        this ();

        this.src.blocksize = BLOCK_SIZE;
        this.src.num_buffers = MAX_BUFFERS;
    }

    public Element? create_stream_source () {
        return this.src;
    }
}

internal abstract class Rygel.HTTPSeek : GLib.Object {
    // These are either number of bytes or microseconds
    public int64 start;
    public int64 stop;
    public int64 length;
    public int64 total_length;
}

internal class Rygel.HTTPTimeSeek : Rygel.HTTPSeek {}

public errordomain Rygel.HTTPRequestError {
    NOT_FOUND = Soup.KnownStatusCode.NOT_FOUND
}
