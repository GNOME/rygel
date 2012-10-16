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

public errordomain Rygel.DataSourceError {
    GENERAL,
    SEEK_FAILED
}

/**
 * Interface for all data streams provided by a #RygelMediaEngine.
 *
 * The data source is responsible for providing the streamable byte-stream
 * via its data_available signal. End-of-stream is signalled by the 
 * done signal, while errors are signalled by the error signal.
 *
 * Implementations should fulfil at least these requirements:
 *
 *  # It should support at least the file:/''''/ URI scheme.
 *  # It should be able to stream any kind of binary data, regardless of the format.
 */
public interface Rygel.DataSource : GLib.Object {
    /**
     * Start producing the data.
     *
     * @param offsets optional limits of the stream for partial streaming
     * @throws Error if anything goes wrong while starting the stream. Throws
     * DataSourceError.SEEK_FAILED if a seek method is not supported or the
     * range is not fulfillable.
     */
    public abstract void start (HTTPSeek? offsets) throws Error;

    /**
     * Temporarily stop data generation.
     *
     * May be called multiple times. If the source is already frozen, the
     * following calles to freeze are ignored. After callging freeze(), so
     * data_available() signal should be emitted.
     */
    public abstract void freeze ();

    /**
     * Resume data generation from a previous freeze call.
     *
     * May be called multiple times, will be ignored if the source is not
     * frozen.
     */
    public abstract void thaw ();

    /**
     * Stop producing data.
     * After calling stop(), calling start() should produce data from the
     * beginning and not resume streaming.
     */
    public abstract void stop ();

    /**
     * Emitted when the source has produced some data.
     */
    public signal void data_available (uint8[] data);

    /**
     * Emitted when the source does not have data anymore.
     */
    public signal void done ();

    /**
     * Emitted when the source encounters a problem during data generation.
     */
    public signal void error (Error error);
}
