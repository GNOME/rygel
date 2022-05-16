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

using Rygel.MediaExport;

const string UPNP_CLASS_PHOTO = "object.item.imageItem.photo";
const string UPNP_CLASS_MUSIC = "object.item.audioItem.musicTrack";
const string UPNP_CLASS_VIDEO = "object.item.videoItem";
const string UPNP_CLASS_PLAYLIST = "object.item.playlistItem";
const string UPNP_CLASS_PLAYLIST_CONTAINER_DVD =
                                      "object.container.playlistContainer.DVD";
const string UPNP_CLASS_DVD_TRACK = UPNP_CLASS_VIDEO + ".dvdTrack";

const string STATUS_LINE_TEMPLATE = "RESULT|%s|%" + size_t.FORMAT + "|%s\n";
const string ERROR_LINE_TEMPLATE = "ERROR|%s|%d|%s\n";
const string SKIPPED_LINE_TEMPLATE = "SKIP|%s|-1|0\n";

static int in_fd = 0;
static int out_fd = 1;
static bool metadata = false;
static MainLoop loop;
static DataInputStream input_stream;
static OutputStream output_stream;

public errordomain MetadataExtractorError {
    GENERAL
}

const OptionEntry[] options = {
    { "input-fd", 'i', 0, OptionArg.INT, ref in_fd, "File descriptor used for input", null },
    { "output-fd", 'o', 0, OptionArg.INT, ref out_fd, "File descriptor used for output", null },
    { "extract-metadata", 'm', 0, OptionArg.NONE, ref metadata,
        "Whether to extract all metadata from the files or just basic information", null },
    { null }
};

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

                try {
                    var file = File.new_for_uri (parts[0]);
                    var extractor = Extractor.create_for_file (file,
                                                               parts[1],
                                                               metadata);
                    yield extractor.run ();

                    send_extraction_done (file, extractor.get ());
                } catch (Error error) {
                    if (error is DVDParserError.NOT_AVAILABLE) {
                        send_skip (File.new_for_uri (parts[0]));
                    } else {
                        warning (_("Failed to discover URI %s: %s"),
                                 parts[0],
                                 error.message);
                        send_error (File.new_for_uri (parts[0]), error);
                    }
                }
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

static bool vaapi_filter (Gst.PluginFeature feature) {
    if (feature.get_name ().has_prefix ("vaapi")) {
        return true;
    }

    return false;
}

int main (string[] args) {
    var ctx = new OptionContext (_("— helper binary for Rygel to extract metadata"));
    ctx.add_main_entries (options, null);
    ctx.add_group (Gst.init_get_option_group ());

    try {
        ctx.parse (ref args);
    } catch (Error error) {
        warning (_("Failed to parse commandline args: %s"), error.message);

        return Posix.EXIT_FAILURE;
    }

    if (Posix.nice (19) < 0) {
        debug ("Failed to reduce nice level of thumbnailer, continuing anyway");
    }

    var registry = Gst.Registry.@get ();
    var features = registry.feature_filter (vaapi_filter, false);
    foreach (var feature in features) {
        debug ("Removing registry feature %s", feature.get_name ());
        registry.remove_feature (feature);
    }

    message ("Started with descriptors %d (in) %d (out), extracting meta-data: %s", in_fd, out_fd, metadata.to_string ());

    input_stream = new DataInputStream (new UnixInputStream (in_fd, true));
    output_stream = new UnixOutputStream (out_fd, true);

    loop = new MainLoop ();

    run.begin ();
    loop.run ();

    return 0;
}
