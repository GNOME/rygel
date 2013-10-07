/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * A simple data source for use with the simple media engine (RygelSimpleMediaEngine).
 *
 * This does not support time-base seeking with 
 * rygel_data_source_start() because it does not
 * use any multimedia framework. Therefore, calling start() with
 * RYGEL_HTTP_SEEK_TYPE_TIME will fail with a 
 * RYGEL_DATA_SOURCE_ERROR_SEEK_FAILED GError code,
 */
internal class Rygel.SimpleDataSource : DataSource, Object {
    private string uri;
    private Thread<void*> thread;
    private Mutex mutex = Mutex ();
    private Cond cond = Cond ();
    private Posix.off_t first_byte = 0;
    private Posix.off_t last_byte = 0;
    private bool frozen = false;
    private bool stop_thread = false;
    private HTTPSeek offsets = null;

    public SimpleDataSource (string uri) {
        debug ("Creating new data source for %s", uri);
        this.uri = uri;
    }

    ~SimpleDataSource () {
        this.stop ();
    }

    public void start (HTTPSeek? offsets) throws Error {
        if (offsets != null) {
            if (offsets.seek_type == HTTPSeekType.TIME) {
                throw new DataSourceError.SEEK_FAILED
                                        (_("Time-based seek not supported"));

            }
        }

        this.offsets = offsets;

        debug ("Starting data source for uri %s", this.uri);

        // TODO: Convert to use a thread pool
        this.thread = new Thread<void*> ("Rygel Serving thread",
                                         this.thread_func);
    }

    public void freeze () {
        if (this.frozen) {
            return;
        }

        this.mutex.lock ();
        this.frozen = true;
        this.mutex.unlock ();
    }

    public void thaw () {
        if (!this.frozen) {
            return;
        }

        this.mutex.lock ();
        this.frozen = false;
        this.cond.broadcast ();
        this.mutex.unlock ();
    }

    public void stop () {
        if (this.stop_thread) {
            return;
        }

        this.mutex.lock ();
        this.frozen = false;
        this.stop_thread = true;
        this.cond.broadcast ();
        this.mutex.unlock ();
    }

    private void* thread_func () {
        var file = File.new_for_commandline_arg (this.uri);
        debug ("Spawning new thread for streaming file %s", this.uri);
        int fd = -1;
        try {
            fd = Posix.open (file.get_path (), Posix.O_RDONLY, 0);
            if (fd < 0) {
                throw new IOError.FAILED ("Failed to open file '%s': %s",
                                          file.get_path (),
                                          Posix.strerror (Posix.errno));
            }

            if (this.offsets != null) {
                this.first_byte = (Posix.off_t) this.offsets.start;
                this.last_byte = (Posix.off_t) this.offsets.stop + 1;
            } else {
                this.first_byte = 0;
                this.last_byte = Posix.lseek (fd, 0, Posix.SEEK_END);
                Posix.lseek (fd, 0, Posix.SEEK_SET);
            }

            if (this.first_byte != 0) {
                 Posix.lseek (fd, this.first_byte, Posix.SEEK_SET);
            }

            while (true) {
                bool exit;
                this.mutex.lock ();
                while (this.frozen) {
                    this.cond.wait (this.mutex);
                }

                exit = this.stop_thread;
                this.mutex.unlock ();

                if (exit || this.first_byte == this.last_byte) {
                    debug ("Done streaming!");

                    break;
                }

                var start = this.first_byte;
                var stop = start + uint16.MAX;
                if (stop > this.last_byte) {
                    stop = this.last_byte;
                }

                var slice = new uint8[stop - start];
                var len = (int) Posix.read (fd, slice, slice.length);
                if (len < 0) {
                    throw new IOError.FAILED ("Failed to read file '%s': %s",
                                              file.get_path (),
                                              Posix.strerror (Posix.errno));
                }

                slice.length = len;
                this.first_byte = stop;

                // There's a potential race condition here.
                Idle.add ( () => {
                    if (!this.stop_thread) {
                        this.data_available (slice);
                    }

                    return false;
                });
            }
        } catch (Error error) {
            warning ("Failed to stream file %s: %s",
                     file.get_path (),
                     error.message);
        } finally {
            Posix.close (fd);
        }

        // Signal that we're done streaming
        Idle.add ( () => { this.done (); return false; });

        return null;
    }
}
