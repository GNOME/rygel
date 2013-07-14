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
    private string id;

    public DVDParser (File file) {
        Object (file : file);
    }

    public override void constructed () {
        unowned string user_cache = Environment.get_user_cache_dir ();
        this.id = this.get_id (this.file);
        var cache_folder = Path.build_filename (user_cache,
                                                "rygel",
                                                "dvd-content");
        DirUtils.create_with_parents (cache_folder, 0700);
        var cache_path = Path.build_filename (cache_folder, this.id);

        this.cache_file = File.new_for_path (cache_path);
    }

    public async void run () throws Error {
        var doc = yield this.get_information ();
        if (doc != null) {
            doc->children;
        }
    }

    public async Xml.Doc* get_information () throws Error {
        if (!this.cache_file.query_exists ()) {
            var launcher = new SubprocessLauncher (SubprocessFlags.STDERR_SILENCE);
            launcher.set_stdout_file_path (this.cache_file.get_path ());
            string[] args = {
                "/usr/bin/lsdvd",
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

    private string get_id (File file) {
        return Checksum.compute_for_string (ChecksumType.MD5,
                                            file.get_uri ());
    }
}
