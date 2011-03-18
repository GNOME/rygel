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

using Gst;

private errordomain Rygel.TestError {
    SKIP
}

private class Rygel.HTTPTranscodeHandler : GLib.Object {}

private abstract class Rygel.MediaItem : GLib.Object {
    public int64 size = -1;

    public bool is_live_stream () {
        return true;
    }
}

private class Rygel.AudioItem : MediaItem {
    public int64 duration = 2048;
}

private class Rygel.Thumbnail : GLib.Object {}
private class Rygel.Subtitle : GLib.Object {}

private class Rygel.HTTPGet : GLib.Object {
    public const string ITEM_URI = "http://DoesntMatterWhatThisIs";

    public Soup.Message msg;
    public MediaItem item;
    public Thumbnail thumbnail;
    public Subtitle subtitle;

    public HTTPTranscodeHandler handler;

    public HTTPGet (Thumbnail? thumbnail, Subtitle? subtitle) {
        this.msg = new Soup.Message ("HTTP", ITEM_URI);
        this.item = new AudioItem ();
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

    private void add_headers (int64 start, int64 stop) requires (start >= 0) {
        var stop_str = (stop > 0)? stop.to_string (): "";
        var range = "npt=" + start.to_string () + "-" + stop_str;
        this.msg.request_headers.append ("TimeSeekRange.dlna.org", range);
    }
}

private class Rygel.HTTPTimeSeekTest : GLib.Object {
    private Regex range_regex;

    public static int main (string[] args) {
        try {
            var test = new HTTPTimeSeekTest ();

            test.run ();
        } catch (TestError.SKIP error) {
            return 77;
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
                this.test_no_seek (thumbnail, subtitle);
                this.test_start_only_seek (thumbnail, subtitle);
                this.test_stop_only_seek (thumbnail, subtitle);
                this.test_start_stop_seek (thumbnail, subtitle);
            }
        }
    }

    private HTTPTimeSeekTest () {
        var expression = "npt=[0-9]+\\.[0-9][0-9]-" +
                         "[0-9]+\\.[0-9][0-9]/" +
                         "[0-9]+\\.[0-9][0-9]";
        this.range_regex = new Regex (expression, RegexCompileFlags.CASELESS);
    }

    private void test_no_seek (Thumbnail? thumbnail,
                               Subtitle?  subtitle) throws HTTPSeekError {
        var request = new HTTPGet (thumbnail, subtitle);
        var audio_item = request.item as AudioItem;

        this.test_seek (request, 0, audio_item.duration - 1);
    }

    private void test_start_only_seek (Thumbnail? thumbnail,
                                       Subtitle?  subtitle)
                                       throws HTTPSeekError {
        var request = new HTTPGet.seek_start (128, thumbnail, subtitle);
        var audio_item = request.item as AudioItem;

        this.test_seek (request, 128, audio_item.duration - 1);
    }

    private void test_stop_only_seek (Thumbnail? thumbnail,
                                      Subtitle?  subtitle)
                                      throws HTTPSeekError {
        var request = new HTTPGet.seek_stop (128, thumbnail, subtitle);

        this.test_seek (request, 0, 128);
    }

    private void test_start_stop_seek (Thumbnail? thumbnail,
                                       Subtitle?  subtitle)
                                       throws HTTPSeekError {
        var request = new HTTPGet.seek_start_stop (128,
                                                   256,
                                                   thumbnail,
                                                   subtitle);

        this.test_seek (request, 128, 256);
    }

    private void test_seek (HTTPGet request,
                            int64   start,
                            int64   stop) throws HTTPSeekError {
        assert (HTTPTimeSeek.needed (request));

        var seek = new HTTPTimeSeek (request);
        seek.add_response_headers ();

        assert (seek != null);
        assert (seek.start == start * SECOND);
        assert (seek.stop == stop * SECOND);
        assert (seek.length == seek.stop + 1 - seek.start);

        var audio_item = request.item as AudioItem;
        assert (seek.total_length == audio_item.duration * SECOND);

        var header = request.msg.response_headers.get_one
                                        ("TimeSeekRange.dlna.org");
        assert (header != null);
        assert (this.range_regex.match (header));
    }
}
