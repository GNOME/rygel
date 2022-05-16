/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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


using Gst;
using Gst.PbUtils;
using Gee;
using GUPnP;
using GUPnPDLNA;

public errordomain MetadataExtractorError {
    GENERAL,
    BLACKLIST
}

/**
 * Metadata extractor based on Gstreamer. Just set the URI of the media on the
 * uri property, it will extact the metadata for you and emit signal
 * metadata_available for each key/value pair extracted.
 */
public class Rygel.MediaExport.MetadataExtractor: GLib.Object {
    private static VariantType SERIALIZED_DATA_TYPE;

    /* Signals */
    public signal void extraction_done (File file, Variant? info);

    /**
     * Signalize that an error occured during metadata extraction
     */
    public signal void error (File file, Error err);

    /// Cache for the config value
    private bool extract_metadata;

    /// Stream for feeding input to the child process.
    private UnixOutputStream input_stream;

    /// Stream for receiving normal input from the child
    private DataInputStream output_stream;

    /// Cancellable for cancelling child I/O
    private Cancellable child_io_cancellable;

    /// Launcher for subprocesses
    private SubprocessLauncher launcher;

    /// URI that caused a fatal error in the extraction process
    private string error_uri = null;

    [CCode (cheader_filename = "glib-unix.h", cname = "g_unix_open_pipe")]
    extern static bool open_pipe ([CCode (array_length = false)]int[] fds, int flags) throws GLib.Error;

    static construct {
        SERIALIZED_DATA_TYPE = new VariantType ("a{sv}");
    }

    public MetadataExtractor () {
        this.child_io_cancellable = new Cancellable ();

        var config = MetaConfig.get_default ();
        config.setting_changed.connect (this.on_config_changed);
        this.on_config_changed (config, Plugin.NAME, "extract-metadata");
    }

    [CCode (cname="MX_EXTRACT_PATH")]
    private extern const string MX_EXTRACT_PATH;

    private string[] MX_EXTRACT_ARGV = {
        MX_EXTRACT_PATH,
        "--input-fd=3",
        "--output-fd=4",
        "--extract-metadata",
        null
    };

    public void stop () {
        this.child_io_cancellable.cancel ();
        try {
            var s = "QUIT\n";
            this.input_stream.write_all (s.data, null, null);
            this.input_stream.flush ();
        } catch (Error error) {
            warning (_("Failed to gracefully stop the process. Using KILL"));
        }
    }

    public async void run () {
        // We use dedicated fds for all of the communication, otherwise the
        // commands/responses intermix with the debug output.
        //
        // This is still wip, we could also use a domain socket or a private
        // DBus

        int[] pipe_in = { 0, 0 };
        int[] pipe_out = { 0, 0 };

        bool restart = false;
        do {
            restart = false;
            try {
                open_pipe (pipe_in, Posix.FD_CLOEXEC);
                open_pipe (pipe_out, Posix.FD_CLOEXEC);

                this.launcher = new SubprocessLauncher (SubprocessFlags.NONE);
                this.launcher.take_fd (pipe_in[0], 3);
                this.launcher.take_fd (pipe_out[1], 4);

                this.input_stream = new UnixOutputStream (pipe_in[1], true);
                this.output_stream = new DataInputStream (
                                                new UnixInputStream (pipe_out[0],
                                                                     true));
                this.child_io_cancellable = new Cancellable ();

                this.output_stream.read_line_async.begin (Priority.DEFAULT,
                                                          this.child_io_cancellable,
                                                          this.on_input);
                this.error_uri = null;

                if (this.extract_metadata) {
                    MX_EXTRACT_ARGV[3] = "--extract-metadata";
                } else {
                    MX_EXTRACT_ARGV[3] = null;
                }

                var subprocess = launcher.spawnv (MX_EXTRACT_ARGV);
                try {
                    yield subprocess.wait_check_async ();
                    // Process exitted properly -> That shouldn't really
                    // happen
                } catch (Error error) {
                    warning (_("Process check_async failed: %s"),
                            error.message);

                    // TODO: Handle error/crash/signal etc.
                    restart = true;
                    this.child_io_cancellable.cancel ();
                    var msg = _("Process died while handling URI %s");
                    this.error (File.new_for_uri (this.error_uri),
                                new MetadataExtractorError.BLACKLIST (msg,
                                                                      this.error_uri));
                }
            } catch (Error error) {
                warning (_("Setting up extraction subprocess failed: %s"),
                         error.message);
            }
        } while (restart);

        debug ("Metadata extractor finished.");
    }

    private void on_input (GLib.Object? object, AsyncResult result) {
        try {
            var stream = object as DataInputStream;
            var str = stream.read_line_async.end (result);

            // XXX: While and Goto language are equivalent. Yuck.
            do {
                if (str == null) {
                    break;
                }

                if (!str.has_prefix ("RESULT|") &&
                    !str.has_prefix ("ERROR|") &&
                    !str.has_prefix ("SKIP|")) {
                    warning (_("Received invalid string from child: %s"), str);

                    break;
                }

                var parts = str.split ("|");
                if (parts.length != 4) {
                    warning (_("Received ill-formed response string %s from child…"),
                             str);

                    break;
                }

                if (parts[0] == "ERROR") {
                    this.error (File.new_for_uri (parts[1]),
                                new MetadataExtractorError.GENERAL (parts[3]));

                    break;
                }

                var uri = parts[1];
                var length = uint64.parse (parts[2]);

                if (parts[0] == "SKIP") {
                    debug ("Extractor binary told us to skip %s",
                           uri);
                    this.extraction_done (File.new_for_uri (uri), null);

                    break;
                }

                debug ("Found serialized data for uri %s", uri);
                var buf = new uint8[length];
                size_t bytes;
                this.output_stream.read_all (buf,
                                             out bytes,
                                             this.child_io_cancellable);
                debug ("Expected %" + size_t.FORMAT + " bytes, got %" +
                       size_t.FORMAT,
                       length,
                       bytes);

                var v = Variant.new_from_data<void*> (SERIALIZED_DATA_TYPE,
                                                      (uchar[]) buf,
                                                      true);
                this.extraction_done (File.new_for_uri (uri), v);
            } while (false);

            this.output_stream.read_line_async.begin (Priority.DEFAULT,
                                                      this.child_io_cancellable,
                                                      this.on_input);
        } catch (Error error) {
            if (error is IOError.CANCELLED) {
                debug ("Read was cancelled, process probably died…");
                // No error signalling, this was done in the part that called
                // cancel
            } else {
                warning (_("Read from child failed: %s"), error.message);
                this.error (File.new_for_uri (this.error_uri),
                            new MetadataExtractorError.GENERAL ("Failed"));

            }
        }
    }

    public void extract (File file, string content_type) {
        if (this.child_io_cancellable.is_cancelled ()) {
            debug ("Child apparently already died, scheduling command for later");
            Idle.add (() => {
                this.extract (file, content_type);

                return false;
            });

            return;
        }

        this.error_uri = file.get_uri ();
        var s = "EXTRACT %s|%s\n".printf (file.get_uri (), content_type);
        try {
            this.input_stream.write_all (s.data, null, this.child_io_cancellable);
            this.input_stream.flush ();
            debug ("Sent command to extractor process: %s", s);
        } catch (Error error) {
            warning (_("Failed to send command to child: %s"), error.message);
        }
    }

    private void on_config_changed (Configuration config,
                                    string section,
                                    string key) {
        if (section != Plugin.NAME || key != "extract-metadata") {
            return;
        }

        try {
            this.extract_metadata = config.get_bool (Plugin.NAME,
                                                     "extract-metadata");
        } catch (Error error) {
            this.extract_metadata = true;
        }

        // if input_stream is not set, then the child is not yet running.
        // Otherwise, if the cancellable is cancelled, then the input stream
        // will not be valid anymore, but the child will be restarted with the
        // new setting anyway.
        if (this.input_stream != null &&
            !this.child_io_cancellable.is_cancelled ()) {
            try {
                var s = "METADATA %s\n".printf (this.extract_metadata.to_string ());
                this.input_stream.write_all (s.data, null, null);
                this.input_stream.flush ();
                debug ("Sent config change to child: %s", s);
            } catch (Error error) {
                debug ("Failed to set meta-data extraction state: %s",
                       error.message);
            }
        }
    }
}
