/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

[CCode (cname="TEST_DATA_FOLDER")]
extern const string TEST_DATA_FOLDER;

// Always test locally built engines
[CCode (cname="TEST_ENGINE_PATH")]
extern const string TEST_ENGINE_PATH;

[CCode (cname="BUILT_ENGINES")]
extern const string BUILT_ENGINES;

/**
 * Helper class to convince the engine loader to load the media engine we want
 * to test.
 */
internal class Rygel.DataSourceTestConfig : Rygel.BaseConfiguration {
    private string engine;
    private string path;

    public DataSourceTestConfig (string? path = null,
                                 string? engine = null) {
        this.engine = engine;
        this.path = path;
    }

    public override string get_media_engine () throws Error {
        if (this.engine != null) {
            return this.engine;
        }

        // Throw error
        return base.get_media_engine ();
    }

    public override string get_engine_path () throws Error {
        if (this.path != null) {
            return this.path;
        }

        return TEST_ENGINE_PATH;
    }

    public string to_string () {
        return "Path: %s, Engine: %s".printf (this.path, this.engine);
    }

    public void clear () {
        this.engine = null;
        this.path = null;
    }
}

internal class Rygel.FakeHandler : Rygel.HTTPGetHandler {
    private int64 length;

    public FakeHandler(int64 length) {
        this.length = length;
    }
    public override bool supports_byte_seek () {
        return true;
    }

    public override int64 get_resource_size () {
        return this.length;
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        throw new HTTPRequestError.NOT_FOUND ("Not found");
    }

    public override bool supports_transfer_mode (string mode) {
        return true;
    }

}

/**
 * Stub implementation of Rygel.HTTPSeek
 */
internal class Rygel.ByteSeek : Rygel.HTTPByteSeekRequest {
    public ByteSeek (int64 first, int64 last, int64 length) {
        var msg = new Soup.Message ("GET", "http://example.com/");
        msg.request_headers.set_content_length (length);
        msg.request_headers.set_range (first, last);
        var handler = new Rygel.FakeHandler (length);

        try {
            base (msg, handler);
        } catch (Error error) {
            assert_not_reached ();
        }
    }
}

/**
 * Wrapper class arount uint8[] arrays to help stuff those buffers into a
 * Gee.ArrayList
 */
class DataBlock {
    public uint8[] data;

    public DataBlock (uint8[] data) {
        this.data = data;
    }
}

/**
 * Helper class to collect a number of byte buffers
 */
internal class Rygel.DataPool : Gee.ArrayList<DataBlock> {
    public uint8[] flatten () {
        var size = this.total_size ();
        var result = new uint8[size];
        var offset = 0;

        foreach (var data in this) {
            Memory.copy (result + offset, (void *) data.data, data.data.length);
            offset += data.data.length;
        }

        this.clear ();
        this.add (new DataBlock (result));

        return result;
    }

    public uint64 total_size () {
        uint64 total = 0;
        foreach (var data in this) {
            total += data.data.length;
        }

        return total;
    }
}

/**
 * Test a DataSource implementation against the expectations of the interface
 *
 * It is run as part of the test suite but can be used to check arbitrary
 * media engines as well:
 *
 * rygel-media-engine-test /path/to/my/first/custom-rygel-engine.so \
 *                         /path/to/my/second/custom-rygel-engine.so ...
 */
public class Rygel.DataSourceTest : Object {
    private File test_data_file;
    private MappedFile test_data_mapped;

    public DataSourceTest () {
        var path = Path.build_filename (TEST_DATA_FOLDER, "test-data.dat");
        this.test_data_file = File.new_for_path (path);
        try {
            this.test_data_mapped = new MappedFile (path, false);
        } catch (Error error) {
            warning ("Error: Could not map file: %s", error.message);
            assert_not_reached ();
        }
    }

    /// Get the whole file
    private void test_simple_streaming () throws Error {
        debug ("test_simple_streaming");
        var source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        // Sources should support file:// urls
        assert (source != null);

        uint64 received_bytes = 0;
        var loop = new MainLoop (null, false);
        source.data_available.connect ( (data) => {
            received_bytes += data.length;
        });
        source.done.connect ( (data) => {
            loop.quit ();
        });

        
        Idle.add ( () => {
            try {
                source.preroll (null, null);
                source.start ();
                return false;
            } catch (GLib.Error error) {
                assert_not_reached ();
            }
        });

        loop.run ();
        assert (received_bytes == this.test_data_mapped.get_length ());
        source.stop ();
        source = null;
    }

    /// Simple byte range request tests
    private void test_byte_range_request () throws Error {
        debug ("test_byte_range_request");
        var source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        // Sources should support file:// urls
        assert (source != null);

        try {
            // Get the first 10 bytes
            var seek = new ByteSeek (0, 9, this.test_data_mapped.get_length ());

            var received_data = new DataPool ();
            var loop = new MainLoop (null, false);
            source.data_available.connect ( (data) => {
                received_data.add (new DataBlock (data));
            });
            source.done.connect ( (data) => {
                loop.quit ();
            });
            source.error.connect ( () => { assert_not_reached (); });
            source.preroll (seek, null);
            source.start ();
            loop.run ();
            assert (received_data.total_size () == 10);
            Memory.cmp (this.test_data_mapped.get_contents (),
                        received_data.flatten (),
                        (size_t) received_data.total_size ());

            // Get last 10 bytes
            seek = new ByteSeek (this.test_data_mapped.get_length () - 10,
                                 this.test_data_mapped.get_length () - 1,
                                 this.test_data_mapped.get_length ());

            received_data = new DataPool ();
            loop = new MainLoop (null, false);

            source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
            source.data_available.connect ( (data) => {
                received_data.add (new DataBlock (data));
            });
            source.done.connect ( (data) => {
                loop.quit ();
            });
            source.error.connect ( () => { assert_not_reached (); });
            source.preroll (seek, null);
            source.start ();
            loop.run ();

            assert (received_data.total_size () == 10);
            Memory.cmp (this.test_data_mapped.get_contents () +
                        (this.test_data_mapped.get_length () - 10),
                        received_data.flatten (),
                        (size_t) received_data.total_size ());

            // Get something from the middle
            seek = new ByteSeek (this.test_data_mapped.get_length () / 2,
                                 (this.test_data_mapped.get_length () / 2) + 9,
                                 this.test_data_mapped.get_length ());

            received_data = new DataPool ();
            loop = new MainLoop (null, false);

            source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
            source.data_available.connect ( (data) => {
                received_data.add (new DataBlock (data));
            });

            source.done.connect ( (data) => {
                loop.quit ();
            });
            source.error.connect ( () => { assert_not_reached (); });
            source.preroll (seek, null);
            source.start ();
            loop.run ();

            assert (received_data.total_size () == 10);
            Memory.cmp (this.test_data_mapped.get_contents () +
                        (this.test_data_mapped.get_length () / 2),
                        received_data.flatten (),
                        (size_t) received_data.total_size ());
            source.stop ();
            source = null;
        } catch (DataSourceError.SEEK_FAILED seek_error) {
            debug ("Skipping seek test");
        } catch (Error error) {
            warning ("Failed to test: %s", error.message);
            assert_not_reached ();
        }
    }

    // Check that calling start() after stop() starts at the beginning of the
    // data
    private void test_stop_start () throws Error {
        debug ("test_stop_start");
        var source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        // Sources should support file:// urls
        assert (source != null);

        var pool = new DataPool ();
        var loop = new MainLoop (null, false);
        source.data_available.connect ( (data) => {
            pool.add (new DataBlock (data));
            source.stop ();
        });
        source.done.connect ( (data) => {
            loop.quit ();
        });

        Idle.add ( () => {
            try {
                source.preroll (null, null);
                source.start ();
                return false;
            } catch (GLib.Error error) {
                assert_not_reached ();
            }
        });


        loop.run ();
        pool.clear ();

        Idle.add ( () => {
            try {
                source.preroll (null, null);
                source.start ();
                return false;
            } catch (GLib.Error error) {
                assert_not_reached ();
            }
        });

        loop.run ();
        Memory.cmp (this.test_data_mapped.get_contents (),
                    pool.flatten (),
                    (size_t) pool.total_size ());

        source.stop ();
        source = null;
    }

    // Check that calling freeze multiple times only needs one thaw to get the
    // data again
    private void test_multiple_freeze () throws Error {
        debug ("test_multiple_freeze");

        var source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        // Sources should support file:// urls
        assert (source != null);
        var available_id = source.data_available.connect ( () => {
            assert_not_reached ();
        });

        try {
            source.preroll (null, null);
            source.start ();
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        source.freeze ();
        source.freeze ();
        var loop = new MainLoop (null, false);

        Timeout.add_seconds (5, () => {
            loop.quit ();

            return false;
        });

        loop.run ();
        source.disconnect (available_id);
        source.data_available.connect ( () => {
            loop.quit ();
        });

        var timeout_id = Timeout.add_seconds (5, () => {
            assert_not_reached ();
        });

        source.thaw ();
        loop.run ();
        Source.remove (timeout_id);
        source.stop ();
    }

    // Check that it is possible to call stop() when the source is frozen and
    // still get a done() signal
    private void test_freeze_stop () throws Error {
        debug ("test_freeze_stop");
        var source = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        // Sources should support file:// urls
        assert (source != null);

        try {
            source.preroll (null, null);
            source.start ();
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        source.freeze ();
        var loop = new MainLoop (null, false);
        source.done.connect ( () => {
            loop.quit ();
        });
        var id = Timeout.add_seconds ( 5, () => {
            assert_not_reached ();
        });
        Idle.add ( () => { source.stop (); return false; });
        loop.run ();
        Source.remove (id);
        source.stop ();
        source = null;
    }

    // Check that it is possible to stream to two targets in parallel
    public void test_parallel_streaming () throws Error {
        debug ("test_parallel_streaming");
        var source1 = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        assert (source1 != null);
        // Sources should support file:// urls
        var source2 = MediaEngine.get_default ().create_data_source_for_uri
                                        (this.test_data_file.get_uri ());
        assert (source2 != null);

        try {
            source1.preroll (null, null);
            source1.start ();
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        var seek = new ByteSeek (0,
                                 (this.test_data_mapped.get_length () / 2),
                                 this.test_data_mapped.get_length ());
        assert (seek != null);

        try {
            source2.preroll (null, null);
            source2.start ();
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        var loop = new MainLoop (null, false);
        var quit = false;
        source1.done.connect ( () => {
            if (quit) {
                loop.quit ();
            } else {
                quit = true;
            }
        });

        source2.done.connect ( () => {
            if (quit) {
                loop.quit ();
            } else {
                quit = true;
            }
        });
        loop.run ();
    }

    public int run () {
        try {
            this.test_simple_streaming ();
            this.test_byte_range_request ();
            this.test_stop_start ();
            this.test_multiple_freeze ();
            this.test_freeze_stop ();
            this.test_parallel_streaming ();
        } catch (Error error) {
            assert_not_reached ();
        }

        return 0;
    }

    public static int main (string[] args) {
        var configs = new Gee.ArrayList<DataSourceTestConfig> ();

        if (args.length > 1) {
            foreach (var arg in args) {
                File file;
                if (args[1].has_prefix ("~")) {
                    file = File.parse_name (args[1]);
                } else {
                   file = File.new_for_commandline_arg (args[1]);
                }
                var path = file.get_parent ().get_path ();
                var engine = file.get_basename ();

                configs.add (new DataSourceTestConfig (path, engine));
            }
        } else {
            foreach (var engine in BUILT_ENGINES.split (";")) {
                var name = engine + "." + Module.SUFFIX;
                configs.add (new DataSourceTestConfig (null, name));
            }
        }

        DataSourceTestConfig previous_config = null;
        foreach (var config in configs) {
            // Invalidate previous config so MetaConfig picks up the
            // current one
            if (previous_config != null) {
                previous_config.clear ();
            }

            debug ("=> Executing tests for config %s", config.to_string ());
            MetaConfig.register_configuration (config);
            previous_config = config;

            try {
                MediaEngine.init ();
            } catch (Error error) {
                assert_not_reached ();
            }

            var test = new DataSourceTest ();

            var result = test.run ();
            if (result != 0) {
                return result;
            }
        }

        return 0;
    }
}
