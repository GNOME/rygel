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
    NOT_AVAILABLE;
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

        var file_uri = GLib.Uri.parse (uri.get_string(), GLib.UriFlags.NONE);

        // Unset size
        this.serialized_info.insert (Serializer.SIZE, "i", -1);

        var context = new Xml.XPath.Context (doc);
        var xpo = context.eval ("/lsdvd/track");
        if ((xpo != null) &&
            (xpo->type == Xml.XPath.ObjectType.NODESET) &&
            (xpo->nodesetval->length () == 1)) {
            var new_uri = Soup.uri_copy(file_uri,
                                        Soup.URIComponent.SCHEME, "dvd",
                                        Soup.URIComponent.QUERY, "title=1",
                                        Soup.URIComponent.NONE);
            this.serialized_info.insert (Serializer.UPNP_CLASS,
                                         "s",
                                         UPNP_CLASS_VIDEO);
            this.serialized_info.insert (Serializer.ID, "s",
                                         "dvd-track:" + id.get_string () + ":0");
            this.serialized_info.insert (Serializer.MIME_TYPE, "s", "video/mpeg");
            this.serialized_info.insert (Serializer.URI, "s",
                                         new_uri.to_string ());

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

    public async Xml.Doc* get_information () throws Error {
        if (!this.cache_file.query_exists ()) {
            var launcher = new SubprocessLauncher (SubprocessFlags.STDERR_SILENCE);
            launcher.set_stdout_file_path (this.cache_file.get_path ());
            string[] args = {
                DVDParser.lsdvd_binary_path,
                "-Ox",
                "-a",
                "-v",
                "-q",
                this.file.get_path (),
                null
            };

            var process = launcher.spawnv (args);
            yield process.wait_async ();

            if (!(process.get_if_exited () &&
                process.get_exit_status () == 0)) {
                try {
                    this.cache_file.delete (null);
                } catch (Error error) {
                    debug ("Failed to delete cache file: %s", error.message);
                }
                throw new DVDParserError.GENERAL ("lsdvd did die or file is not a DVD");
            }
        }

        return Xml.Parser.read_file (this.cache_file.get_path (),
                                     null,
                                     Xml.ParserOption.NOERROR |
                                     Xml.ParserOption.NOWARNING |
                                     Xml.ParserOption.NONET);
    }
}
