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

using Soup;

/**
 * Class that converts the push DataSource into the pull required by libsoup.
 */
internal class Rygel.DataSink : Object {
    private DataSource source;
    private Server server;
    private Message message;

    private const uint MAX_BUFFERED_CHUNKS = 32;
    private const uint MIN_BUFFERED_CHUNKS = 4;

    private int64 chunks_buffered;
    private int64 bytes_sent;
    private int64 max_bytes;

    public DataSink (DataSource source,
                     Server     server,
                     Message    message,
                     HTTPSeek?  offsets) {
        this.source = source;
        this.server = server;
        this.message = message;

        this.chunks_buffered = 0;
        this.bytes_sent = 0;
        this.max_bytes = int64.MAX;
        if (offsets != null &&
            offsets is HTTPByteSeek) {
            this.max_bytes = offsets.length;
        }

        this.source.data_available.connect (this.on_data_available);
        this.message.wrote_chunk.connect (this.on_wrote_chunk);
    }

    private void on_wrote_chunk (Soup.Message msg) {
        this.chunks_buffered--;
        if (this.chunks_buffered < MIN_BUFFERED_CHUNKS) {
            this.source.thaw ();
        }
    }

    private void on_data_available (uint8[] buffer) {
        var left = this.max_bytes - this.bytes_sent;

        if (left <= 0) {
            return;
        }

        var to_send = int64.min (buffer.length, left);

        this.message.response_body.append (Soup.MemoryUse.COPY,
                                           buffer[0:to_send]);
        this.chunks_buffered++;
        this.bytes_sent += to_send;

        this.server.unpause_message (this.message);

        if (this.chunks_buffered > MAX_BUFFERED_CHUNKS) {
            this.source.freeze ();
        }
    }
}
