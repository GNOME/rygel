/*
 * Copyright (C) 2013,2015 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal errordomain DVDParserError {
    GENERAL,
    NOT_AVAILABLE,
    GSTREAMER_NOT_AVAILABLE;
}

internal class Rygel.MediaExport.DVDParser : Extractor {
    private File cache_file;
    private static string? lsdvd_binary_path;

    public DVDParser (File file) {
        Object (file : file);
    }

    static construct {
        string? path = Environment.find_program_in_path ("lsdvd");
        if (path == null) {
            var msg = _("Failed to find lsdvd binary in path. DVD extraction will not be available");
            warning (msg);
        }

        DVDParser.lsdvd_binary_path = path;
    }

    public static string get_cache_path (string image_path) {
        unowned string user_cache = Environment.get_user_cache_dir ();
        var id = Checksum.compute_for_string (ChecksumType.MD5, image_path);
        var cache_folder = Path.build_filename (user_cache,
                                                "rygel",
                                                "dvd-content");
        DirUtils.create_with_parents (cache_folder, 0700);

        return Path.build_filename (cache_folder, id);
    }

    public override void constructed () {
        base.constructed ();

        var path = DVDParser.get_cache_path (this.file.get_path ());
        this.cache_file = File.new_for_path (path);
    }

    public async override void run () throws Error {
        yield base.run ();

        if (DVDParser.lsdvd_binary_path == null) {
            throw new DVDParserError.NOT_AVAILABLE ("No DVD extractor found");
        }

        var doc = yield this.get_information ();
        if (doc == null) {
            throw new DVDParserError.GENERAL ("Failed to read cache file");
        }

        var id = this.serialized_info.lookup_value (Serializer.ID,
                                                    VariantType.STRING);
        var uri = this.serialized_info.lookup_value (Serializer.URI,
                                                     VariantType.STRING);

        // Unset size
        this.serialized_info.insert (Serializer.SIZE, "i", -1);

        var context = new Xml.XPath.Context (doc);
        var xpo = context.eval ("/lsdvd/track");
        if ((xpo != null) &&
            (xpo->type == Xml.XPath.ObjectType.NODESET) &&
            (xpo->nodesetval->length () == 1)) {
            var new_uri = new Soup.URI (uri.get_string ());
            new_uri.set_scheme ("dvd");
            new_uri.set_query ("title=1");
            this.serialized_info.insert (Serializer.UPNP_CLASS,
                                         "s",
                                         UPNP_CLASS_VIDEO);
            this.serialized_info.insert (Serializer.ID, "s",
                                         "dvd-track:" + id.get_string () + ":0");
            this.serialized_info.insert (Serializer.MIME_TYPE, "s", "video/mpeg");
            this.serialized_info.insert (Serializer.URI, "s",
                                         new_uri.to_string (false));

            var node = xpo->nodesetval->item (0);

            var it = node->children;
            while (it != null) {
                if (it->name == "length") {
                    var duration =  (int) double.parse (it->children->content);

                    this.serialized_info.insert (Serializer.DURATION,
                                                 "i",
                                                 duration);
                } else if (it->name == "width") {
                    var width = int.parse (it->children->content);
                    this.serialized_info.insert (Serializer.VIDEO_WIDTH,
                                                 "i",
                                                 width);
                } else if (it->name == "height") {
                    var height = int.parse (it->children->content);
                    this.serialized_info.insert (Serializer.VIDEO_HEIGHT,
                                                 "i",
                                                 height);
                } else if (it->name == "format") {
                    var dlna_profile = "MPEG_PS_" + it->children->content;
                    this.serialized_info.insert (Serializer.DLNA_PROFILE,
                                                 "s",
                                                 dlna_profile);
                }
                // TODO: Japanese formats...

                it = it->next;
            }
        } else {
            this.serialized_info.insert (Serializer.ID, "s",
                                         "dvd:" + id.get_string ());
            this.serialized_info.insert (Serializer.UPNP_CLASS,
                                         "s",
                                         UPNP_CLASS_PLAYLIST_CONTAINER_DVD);
            this.serialized_info.insert (Serializer.MIME_TYPE,
                                         "s",
                                         "application/x-cd-image");
        }

        if (xpo != null) {
            delete xpo;
        }

        delete doc;
    }

    public async void get_information () throws Error {
        if (!this.cache_file.query_exists ()) {
            string[] args = {
                DVDParser.lsdvd_binary_path,
                "-Ox",
                "-a",
                "-v",
                "-q",
                this.file.get_path (),
                null
            };

            var process = new Subprocess.newv (args, SubprocessFlags.STDOUT_PIPE);

            string buffer;

            yield process.communicate_utf8_async (null, null, out buffer, null);

            if (!(process.get_if_exited () &&
                process.get_exit_status () == 0)) {
                try {
                    this.cache_file.delete (null);
                } catch (Error error) {
                    debug ("Failed to delete cache file: %s", error.message);
                }
                throw new DVDParserError.GENERAL ("lsdvd did die or file is not a DVD");
            }

            var doc = Xml.Parser.read_memory (buffer,
                                              buffer.length,
                                              null,
                                              "UTF-8",
                                              Xml.ParserOption.NOBLANKS |
                                              Xml.ParserOption.NOERROR |
                                     Xml.ParserOption.NOWARNING |
                                     Xml.ParserOption.NONET);
            var context = new Xml.XPath.Context (doc);
            var result = context.eval_expression ("/lsdvd/track");

            if (result != null) {
                if (result->type == Xml.XPath.ObjectType.NODESET &&
                    result->nodesetval->length () == 1) {
                    var node = result->nodesetval->item (0);
                    try {
                        var duration = yield this.query_length ();
                        var duration_node = doc->new_node (null,
                                                           "rygel:bytelength",
                                                           "%lld".printf (duration));
                        node->add_child (duration_node);
                    } catch (Error error) {
                        warning (_("Failed to query length from DVD: %s"),
                                 error.message);
                    }
                }

                delete result;
            }

            doc->dump_memory_enc_format (out buffer, null, "UTF-8", false);
            delete doc;

            yield this.cache_file.replace_contents_async (buffer.data,
                                                          null,
                                                          false,
                                                          FileCreateFlags.NONE,
                                                          null,
                                                          null);
         }
    }

    private async int64 query_length () throws Error {
        bool failed = false;

        var pipeline = new Gst.Pipeline ("DVD title size query");
        dynamic Gst.Element? src = Gst.ElementFactory.make ("dvdreadsrc", "src");
        var sink = Gst.ElementFactory.make ("fakesink", "sink");

        if (src == null) {
            var msg = _("The dvdreadsrc plugin is not installed. DVD support will not work");
            throw new DVDParserError.GSTREAMER_NOT_AVAILABLE (msg);
        }

        pipeline.add_many (src, sink);
        src.link (sink);
        src.device = file.get_path ();

        var bus = pipeline.get_bus ();
        bus.add_signal_watch ();
        bus.message["state-changed"].connect ( (b, msg) => {
            if (msg.src == pipeline) {
                Gst.State new_state;
                msg.parse_state_changed (null, out new_state, null);
                if (new_state == Gst.State.PAUSED) {
                    query_length.callback ();
                }
            }
        });

        bus.message["error"].connect ( () => {
            failed = true;
            query_length.callback ();
        });

        pipeline.set_state (Gst.State.PAUSED);
        yield;
        bus.remove_signal_watch ();

        if (failed) {
            throw new DVDParserError.GENERAL (_("Querying the size of the tile failed"));
        }

        int64 duration;
        pipeline.query_duration (Gst.Format.BYTES, out duration);

        warning ("DVD title has %lld bytes", duration);

        return duration;
    }
}
