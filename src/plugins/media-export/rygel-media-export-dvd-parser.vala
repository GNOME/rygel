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
    GENERAL;
}

internal class Rygel.DVDParser : GLib.Object {
    /// URI to the image / toplevel directory
    public File file { public get; construct; }

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
        var path = DVDParser.get_cache_path (this.file.get_path ());
        this.cache_file = File.new_for_path (path);
    }

    public async void run () throws Error {
        if (DVDParser.lsdvd_binary_path == null) {
            throw new DVDParserError.GENERAL ("No DVD extractor found");
        }

        yield this.get_information ();
    }

    public async Xml.Doc* get_information () throws Error {
        if (!this.cache_file.query_exists ()) {
            var launcher = new SubprocessLauncher (SubprocessFlags.STDERR_SILENCE);
            launcher.set_stdout_file_path (this.cache_file.get_path ());
            string[] args = {
                DVDParser.lsdvd_binary_path,
                "-Ox",
                "-x",
                "-q",
                this.file.get_path (),
                null
            };

            var process = launcher.spawnv (args);
            yield process.wait_async ();

            if (!(process.get_if_exited () &&
                process.get_exit_status () == 0)) {
                throw new DVDParserError.GENERAL ("lsdvd did die or file is not a DVD");
            }
        }

        return Xml.Parser.read_file (this.cache_file.get_path (),
                                     null,
                                     Xml.ParserOption.NOERROR |
                                     Xml.ParserOption.NOWARNING);
    }
}
