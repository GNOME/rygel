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

public class Rygel.SeekableResponseTest : Rygel.HTTPResponseTest {
    private static string URI = "file:///tmp/rygel-dummy-test-file";

    private File dummy_file;

    public static int main (string[] args) {
        try {
            var test = new SeekableResponseTest.complete ();
            test.run ();

            test = new SeekableResponseTest.abort ();
            test.run ();
        } catch (TestError.SKIP error) {
            return error.code;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    private SeekableResponseTest (Cancellable? cancellable = null)
                                  throws Error {
        base (cancellable);
    }

    private SeekableResponseTest.complete () throws Error {
        base.complete ();
    }

    private SeekableResponseTest.abort () throws Error {
        base.abort ();
    }

    public override void run () throws Error {
        this.create_dummy_file ();

        base.run ();

        this.dummy_file.delete (null);
    }

    private void create_dummy_file () throws Error {
        this.dummy_file = File.new_for_uri (URI);
        var stream = this.dummy_file.replace (null, false, 0, null);

        // Put randon stuff into it
        stream.write (new char[1024], 1024, null);
    }

    internal override HTTPResponse create_response (Soup.Message msg)
                                                    throws Error {
        var seek = new HTTPSeek (0, 1025);

        return new SeekableResponse (this.server.context.server,
                                     msg,
                                     this.dummy_file.get_uri (),
                                     seek,
                                     1024,
                                     this.cancellable);
    }
}
