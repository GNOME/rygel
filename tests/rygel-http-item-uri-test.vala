/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshan.ali@nokia.com>
 *                               <zeeshanak@gnome.org>
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

private errordomain Rygel.HTTPRequestError {
    UNACCEPTABLE = Soup.KnownStatusCode.NOT_ACCEPTABLE,
    BAD_REQUEST = Soup.KnownStatusCode.BAD_REQUEST,
    NOT_FOUND = Soup.KnownStatusCode.NOT_FOUND
}

private errordomain Rygel.TestError {
    SKIP
}

private class Rygel.HTTPServer : GLib.Object {
    private const string SERVER_PATH = "/Test";

    public string path_root { get; private set; }

    public GUPnP.Context context;

    public HTTPServer () throws TestError {
        this.path_root = SERVER_PATH;

        try {
            this.context = new GUPnP.Context (null, "lo", 0);
        } catch (Error error) {
            throw new TestError.SKIP ("Network context not available");
        }

        assert (this.context != null);
        assert (this.context.host_ip != null);
        assert (this.context.port > 0);
    }
}

private class Rygel.HTTPItemURITest : GLib.Object {
    private const string ITEM_ID = "HELLO";
    private const int THUMBNAIL_INDEX = 1;
    private const int SUBTITLE_INDEX = 1;
    private const string TRANSCODE_TARGET = "MP3";

    private HTTPServer server;

    public static int main (string[] args) {
        try {
            var test = new HTTPItemURITest ();

            test.run ();
        } catch (TestError.SKIP error) {
            return 77;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    public void run () throws Error {
        var uris = new HTTPItemURI[] {
            this.test_construction (),
            this.test_construction_with_thumbnail (),
            this.test_construction_with_subtitle (),
            this.test_construction_with_transcoder () };

        foreach (var uri in uris) {
            var str = this.test_to_string (uri);
            this.test_construction_from_string (str);
        }
    }

    private HTTPItemURITest () throws TestError {
        this.server = new HTTPServer ();
    }

    private HTTPItemURI test_construction () {
        var uri = new HTTPItemURI (ITEM_ID, this.server);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_with_subtitle () {
        var uri = new HTTPItemURI (ITEM_ID,
                                   this.server,
                                   -1,
                                   SUBTITLE_INDEX);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_with_thumbnail () {
        var uri = new HTTPItemURI (ITEM_ID,
                                   this.server,
                                   THUMBNAIL_INDEX);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_with_transcoder () {
        var uri = new HTTPItemURI (ITEM_ID,
                                   this.server,
                                   THUMBNAIL_INDEX,
                                   -1,
                                   TRANSCODE_TARGET);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_from_string (string str)
                                                       throws Error {
        var uri = new HTTPItemURI.from_string (str, this.server);
        assert (uri != null);
        assert (uri.to_string () == str);

        return uri;
    }

    private string test_to_string (HTTPItemURI uri) {
        var str = uri.to_string ();
        assert (str != null);

        return str;
    }
}
