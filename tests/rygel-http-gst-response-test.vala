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
    private static const long BLOCK_SIZE = MAX_BYTES / 16;
    private static const long MAX_BUFFERS = MAX_BYTES / BLOCK_SIZE;

    private dynamic Element src;

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

    construct {
        this.src = GstUtils.create_element ("audiotestsrc", null);
    }

    private HTTPGstResponseTest.complete () throws Error {
        base.complete ();

        this.src.blocksize = BLOCK_SIZE;
        this.src.num_buffers = MAX_BUFFERS;
    }

    private HTTPGstResponseTest.abort () throws Error {
        base.abort ();
    }

    internal override HTTPResponse create_response (Soup.Message msg)
                                                     throws Error {
        return new HTTPGstResponse (this.server.context.server,
                                    msg,
                                    "TestingHTTPGstResponse",
                                    this.src,
                                    null,
                                    this.cancellable);
    }
}
