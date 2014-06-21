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

private errordomain Rygel.TestError {
    SKIP
}

private class Rygel.HTTPTranscodeHandler : GLib.Object {}

public class Rygel.MediaObject : GLib.Object {
    public int64 size = -1;
}

public class Rygel.MediaContainer : MediaObject {
}

private abstract class Rygel.MediaFileItem : MediaObject {
    public bool is_live_stream () {
        return true;
    }
}

private class Rygel.AudioItem : MediaFileItem {
    public int64 duration = 2048;
}

public class Rygel.ClientHacks : GLib.Object {
    public static ClientHacks create (Soup.Message msg) throws Error {
        return new ClientHacks ();
    }

    public bool force_seek () {
        return false;
    }
}

private class Rygel.Thumbnail : GLib.Object {}
private class Rygel.Subtitle : GLib.Object {}

private class Rygel.HTTPGet : GLib.Object {
    public const string ITEM_URI = "http://DoesntMatterWhatThisIs";

    public Soup.Message msg;
    public MediaObject object;
    public Thumbnail thumbnail;
    public Subtitle subtitle;

    public HTTPTranscodeHandler handler;

    public HTTPGet (Thumbnail? thumbnail, Subtitle? subtitle) {
        this.msg = new Soup.Message ("HTTP", ITEM_URI);
        this.object = new AudioItem ();
        this.handler = new HTTPTranscodeHandler ();
        this.thumbnail = thumbnail;
        this.subtitle = subtitle;
    }

    public HTTPGet.seek_start (int64      start,
                               Thumbnail? thumbnail,
                               Subtitle?  subtitle) {
        this (thumbnail, subtitle);

        this.add_headers (start, -1);
    }

    public HTTPGet.seek_stop (int64      stop,
                              Thumbnail? thumbnail,
                              Subtitle?  subtitle) {
        this (thumbnail, subtitle);

        this.add_headers (0, stop);
    }

    public HTTPGet.seek_start_stop (int64      start,
                                    int64      stop,
                                    Thumbnail? thumbnail,
                                    Subtitle?  subtitle) {
        this (thumbnail, subtitle);

        this.add_headers (start, stop);
    }

    public HTTPGet.seek_strings (string     start,
                                 string     stop,
                                 Thumbnail? thumbnail,
                                 Subtitle?  subtitle) {
        this (thumbnail, subtitle);

        this.add_string_headers (start, stop);
    }

    private void add_headers (int64 start, int64 stop) requires (start >= 0) {
        var stop_str = (stop > 0)? stop.to_string (): "";
        var range = "npt=" + start.to_string () + "-" + stop_str;
        this.msg.request_headers.append ("TimeSeekRange.dlna.org", range);
    }

    private void add_string_headers (string start, string stop) {
        var range = "npt=" + start + "-" + stop;
        this.msg.request_headers.append ("TimeSeekRange.dlna.org", range);
    }
}

private class Rygel.HTTPTimeSeekTest : GLib.Object {
    private Regex range_regex;

    enum TestType {
        TEST_SECONDS_PARSING,
        TEST_HHMMSS_PARSING,
        TEST_MIXED_PARSING
    }
    private TestType test_type;

    public static int main (string[] args) {
        try {
            var test = new HTTPTimeSeekTest ();

            test.run ();
        /* TODO: Nothing throws this exception. Should it?
        } catch (TestError.SKIP error) {
            return 77;
        */
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    public void run () throws HTTPSeekError {
        var thumbnails = new Thumbnail[] { null, new Thumbnail () };
        var subtitles = new Subtitle[] { null, new Subtitle () };

        foreach (var thumbnail in thumbnails) {
            foreach (var subtitle in subtitles) {
                this.test_type = TestType.TEST_SECONDS_PARSING;
                this.test_no_seek (thumbnail, subtitle);
                this.test_start_only_seek (thumbnail, subtitle);
                this.test_stop_only_seek (thumbnail, subtitle);
                this.test_start_stop_seek (thumbnail, subtitle);
                this.test_type = TestType.TEST_HHMMSS_PARSING;
                this.test_start_only_seek (thumbnail, subtitle);
                this.test_stop_only_seek (thumbnail, subtitle);
                this.test_start_stop_seek (thumbnail, subtitle);
                this.test_type = TestType.TEST_MIXED_PARSING;
                this.test_start_stop_seek (thumbnail, subtitle);
            }
        }
    }

    private HTTPTimeSeekTest () {
        var expression = "npt=[0-9]+\\.[0-9][0-9][0-9]-" +
                         "[0-9]+\\.[0-9][0-9][0-9]/" +
                         "[0-9]+\\.[0-9][0-9][0-9]";

        try {
            this.range_regex = new Regex (expression, RegexCompileFlags.CASELESS);
        } catch (RegexError error) {
            // This means that it is not a regular expression
            assert_not_reached ();
        }
    }

    private void test_no_seek (Thumbnail? thumbnail,
                               Subtitle?  subtitle) throws HTTPSeekError {
        var request = new HTTPGet (thumbnail, subtitle);
        var audio_item = request.object as AudioItem;
        this.test_seek (request,
                        0,
                        audio_item.duration * TimeSpan.SECOND - TimeSpan.MILLISECOND);
    }

    private void test_start_only_seek (Thumbnail? thumbnail,
                                       Subtitle?  subtitle)
                                       throws HTTPSeekError {
        HTTPGet request = null;

        switch (this.test_type) {
        case TestType.TEST_SECONDS_PARSING:
            request = new HTTPGet.seek_start (128, thumbnail, subtitle);

            break;

        case TestType.TEST_HHMMSS_PARSING:
            request = new HTTPGet.seek_strings ("00:02:08.000", "", thumbnail, subtitle);

            break;
        }

        var audio_item = request.object as AudioItem;
        this.test_seek (request,
                        128 * TimeSpan.SECOND,
                        audio_item.duration * TimeSpan.SECOND - TimeSpan.MILLISECOND);
    }

    private void test_stop_only_seek (Thumbnail? thumbnail,
                                      Subtitle?  subtitle)
                                      throws HTTPSeekError {
        HTTPGet request = null;

        switch (this.test_type) {
        case TestType.TEST_SECONDS_PARSING:
            request = new HTTPGet.seek_stop (128, thumbnail, subtitle);

            break;

        case TestType.TEST_HHMMSS_PARSING:
            request = new HTTPGet.seek_strings ("00:00:00.000",
                                                "00:02:08.000",
                                                thumbnail,
                                                subtitle);

            break;
        }

        this.test_seek (request, 0, 128 * TimeSpan.SECOND);
    }

    private void test_start_stop_seek (Thumbnail? thumbnail,
                                       Subtitle?  subtitle)
                                       throws HTTPSeekError {
        HTTPGet request = null;

        switch (this.test_type) {
        case TestType.TEST_SECONDS_PARSING:
            request = new HTTPGet.seek_start_stop (128,
                                                   256,
                                                   thumbnail,
                                                   subtitle);

            break;

        case TestType.TEST_HHMMSS_PARSING:
            request = new HTTPGet.seek_strings ("00:02:08.000",
                                                "00:04:16.000",
                                                thumbnail,
                                                subtitle);

            break;

        case TestType.TEST_MIXED_PARSING:
            request = new HTTPGet.seek_strings ("00:02:08.000",
                                                "256.000",
                                                thumbnail,
                                                subtitle);

            break;
        }


        this.test_seek (request, 128 * TimeSpan.SECOND, 256 * TimeSpan.SECOND);
    }

    private void test_seek (HTTPGet request,
                            int64   start,
                            int64   stop) throws HTTPSeekError {
        assert (HTTPTimeSeek.needed (request));

        var seek = new HTTPTimeSeek (request);
        seek.add_response_headers ();

        assert (seek != null);
        assert (seek.start == start);
        assert (seek.stop == stop - 1);
        assert (seek.length == seek.stop + TimeSpan.MILLISECOND - seek.start);

        var audio_item = request.object as AudioItem;
        assert (seek.total_length == audio_item.duration * TimeSpan.SECOND);

        var header = request.msg.response_headers.get_one
                                        ("TimeSeekRange.dlna.org");
        assert (header != null);
        assert (this.range_regex.match (header));

        /* TODO: This is just here to avoid a warning about
         * requested() not being used.
         * How should this really be tested?
         * Sometimes the result here is true, and sometimes it is false.
         */
        /* bool result = */ HTTPTimeSeek.requested(request);
    }
}
