/*
 * Copyright (C) 2015 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gst.PbUtils;
using GUPnPDLNA;
using Gst;

struct UriBuffer {
    uint8 data[4096];
    size_t length;
}

const string UPNP_CLASS_PHOTO = "object.item.imageItem.photo";
const string UPNP_CLASS_MUSIC = "object.item.audioItem.musicTrack";
const string UPNP_CLASS_VIDEO = "object.item.videoItem";
const string UPNP_CLASS_PLAYLIST = "object.item.playlistItem";
const string UPNP_CLASS_PLAYLIST_CONTAINER_DVD =
                                      "object.container.playlistContainer.DVD";

const string STATUS_LINE_TEMPLATE = "RESULT|%s|%" + size_t.FORMAT + "|%s\n";
const string ERROR_LINE_TEMPLATE = "ERROR|%s|%d|%s\n";
const string SKIPPED_LINE_TEMPLATE = "SKIP|%s|-1|0\n";

const string FATAL_ERROR_PREFIX = "FATAL_ERROR|";
const string FATAL_ERROR_SUFFIX = "\n"; //|0|Killed by signal\n";

static int in_fd = 0;
static int out_fd = 1;
static int err_fd = 2;
static bool metadata = false;
static MainLoop loop;
static DataInputStream input_stream;
static OutputStream output_stream;
static OutputStream error_stream;
static Rygel.InfoSerializer serializer;
static MediaArt.Process media_art;
static Discoverer discoverer;
static ProfileGuesser guesser;
static UriBuffer last_uri;

public errordomain MetadataExtractorError {
    GENERAL
}

static const OptionEntry[] options = {
    { "input-fd", 'i', 0, OptionArg.INT, ref in_fd, "File descriptor used for input", null },
    { "output-fd", 'o', 0, OptionArg.INT, ref out_fd, "File descriptor used for output", null },
    { "error-fd", 'e', 0, OptionArg.INT, ref err_fd, "File descriptor used for severe errors", null },
    { "extract-metadata", 'm', 0, OptionArg.NONE, ref metadata,
        "Whether to extract all metadata from the files or just basic information", null },
    { null }
};

static void segv_handler (int signal) {
    Posix.write (err_fd, (void *) last_uri.data, last_uri.length);
    Posix.write (err_fd, (void *) FATAL_ERROR_SUFFIX, 1);
    Posix.fsync (err_fd);

    Posix.exit(-1);
}

async void run () {
    while (true) {
        try {
            var line = yield input_stream.read_line_async ();
            if (line == null) {
                break;
            }

            if (line.has_prefix ("EXTRACT ")) {
                debug ("Got command to extract file: %s", line);
                var data = line.replace ("EXTRACT ", "").strip ();
                var parts = data.split ("|");
                if (parts.length != 2) {
                    warning (_("Invalid command received, ignoring"));

                    continue;
                }
                DiscovererInfo? info = null;
                try {
                    // Copy current URI to statically allocated memory area to
                    // dump to fd in the signal handler
                    last_uri.length = parts[0].length;
                    GLib.Memory.set (last_uri.data, 0, 4096);
                    GLib.Memory.copy (last_uri.data,
                                      (void *) parts[0],
                                      parts[0].length);
                    if (metadata) {
                        var is_text = parts[1].has_prefix ("text/") ||
                                      parts[1].has_suffix ("xml");
                        if (parts[1] == "application/x-cd-image") {
                            var file = File.new_for_uri (parts[0]);
                            var parser = new Rygel.DVDParser (file);
                            yield parser.run ();
                        } else if (!is_text) {
                            info = discoverer.discover_uri (parts[0]);

                            debug ("Finished discover on URI %s", parts[0]);
                        }
                    }
                    yield process_meta_data (parts[0], info);
                } catch (Error error) {
                    if (error is DVDParserError.NOT_AVAILABLE) {
                        send_skip (File.new_for_uri (parts[0]));
                    } else {
                        warning (_("Failed to discover URI %s: %s"),
                                 parts[0],
                                 error.message);
                        send_error (File.new_for_uri (parts[0]), error);

                        // Recreate the discoverer on error
                        discoverer = new Discoverer (10 * Gst.SECOND);
                    }
                }
                //discoverer.discover_uri_async (uri);
            } else if (line.has_prefix ("METADATA ")) {
                var command = line.replace ("METADATA ", "").strip ();
                metadata = bool.parse (command);
                debug ("Meta-data extraction was %s",
                       metadata ? "enabled" : "disabled");
            } else if (line.has_prefix ("QUIT")) {
                break;
            }
        } catch (Error error) {
            warning (_("Failed to read from pipe: %s"), error.message);

            break;
        }
    }

    loop.quit ();
}

static void send_extraction_done (File file, Variant v) throws Error {
    var data = v.get_data_as_bytes ();
    size_t bytes_written = 0;
    var status = STATUS_LINE_TEMPLATE.printf (file.get_uri (),
                                              data.get_size (),
                                              file.get_uri ());

    output_stream.write_all (status.data, out bytes_written);
    output_stream.write_all (data.get_data (), out bytes_written);
}

static void send_skip (File file) {
    size_t bytes_written = 0;
    var status = SKIPPED_LINE_TEMPLATE.printf (file.get_uri ());

    try {
        output_stream.write_all (status.data, out bytes_written);
    } catch (Error error) {
        warning (_("Failed to send error to parent: %s"), error.message);
    }
}

static void send_error (File file, Error err) {
    size_t bytes_written = 0;
    var status = ERROR_LINE_TEMPLATE.printf (file.get_uri (),
                                             err.code,
                                             err.message);
    try {
        output_stream.write_all (status.data, out bytes_written);
    } catch (Error error) {
        warning (_("Failed to send error to parent: %s"), error.message);
    }
}

static async void process_meta_data (string uri, DiscovererInfo? info) {
    debug ("Discovered %s", uri);
    var file = File.new_for_uri (uri);
    if (info != null) {
        if (info.get_result () == DiscovererResult.TIMEOUT ||
            info.get_result () == DiscovererResult.BUSY ||
            info.get_result () == DiscovererResult.MISSING_PLUGINS) {
            if (info.get_result () == DiscovererResult.MISSING_PLUGINS) {
                debug ("Plugins are missing for extraction of file %s",
                       info.get_uri ());
            } else {
                debug ("Extraction timed out on %s", file.get_uri ());
            }
            yield extract_basic_information (file, null, null);

            return;
        }

        var dlna_info = GUPnPDLNAGst.utils_information_from_discoverer_info (info);
        var dlna = guesser.guess_profile_from_info (dlna_info);
        yield extract_basic_information (file, info, dlna);
    } else {
        yield extract_basic_information (file, null, null);
    }
}

static async void extract_basic_information (File               file,
                                             DiscovererInfo?    info,
                                             GUPnPDLNA.Profile? dlna) {
    FileInfo file_info;

    try {
        file_info = yield file.query_info_async (FileAttribute.STANDARD_TYPE + "," +
                                                 FileAttribute.STANDARD_CONTENT_TYPE
                                                 + "," +
                                                 FileAttribute.STANDARD_SIZE + "," +
                                                 FileAttribute.TIME_MODIFIED + "," +
                                                 FileAttribute.STANDARD_DISPLAY_NAME,
                                                 FileQueryInfoFlags.NONE);
    } catch (Error error) {
        var uri = file.get_uri ();

        warning (_("Failed to extract basic metadata from %s: %s"),
                 uri,
                 error.message);

        // signal error to parent
        send_error (file, error);

        return;
    }

    if (file_info.get_file_type () == FileType.DIRECTORY) {
        file_info.set_file_type (FileType.REGULAR);
        file_info.set_content_type ("application/x-cd-image");
    }

    try {
        send_extraction_done (file,
                              serializer.serialize (file, file_info, info, dlna));
    } catch (Error error) {
        send_error (file, error);
    }
}

int main (string[] args) {
    var ctx = new OptionContext (_("- helper binary for Rygel to extract metadata"));
    ctx.add_main_entries (options, null);
    ctx.add_group (Gst.init_get_option_group ());

    try {
        ctx.parse (ref args);
    } catch (Error error) {
        warning (_("Failed to parse commandline args: %s"), error.message);

        return Posix.EXIT_FAILURE;
    }

    try {
        media_art = new MediaArt.Process ();
    } catch (Error error) {
        warning (_("Failed to create media art extractor: %s"),
                error.message);
    }
    serializer = new Rygel.InfoSerializer (media_art);
    Posix.nice (19);

    var action = new Posix.sigaction_t ();
    action.sa_handler = segv_handler;
    Posix.sigaction (Posix.SIGSEGV, action, null);
    Posix.sigaction (Posix.SIGABRT, action, null);

    message ("Started with descriptors %d %d %d", in_fd, out_fd, err_fd);

    input_stream = new DataInputStream (new UnixInputStream (in_fd, true));
    output_stream = new UnixOutputStream (out_fd, true);
    error_stream = new UnixOutputStream (err_fd, true);

    loop = new MainLoop ();
    try {
        discoverer = new Discoverer (10 * Gst.SECOND);
    } catch (Error error) {
        warning (_("Failed to start metadata discoverer: %s"),
                 error.message);
    }

    guesser = new ProfileGuesser (true, true);

    run.begin ();
    loop.run ();

    return 0;
}
