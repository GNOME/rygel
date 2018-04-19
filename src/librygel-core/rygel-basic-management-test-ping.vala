/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Christophe Guiraud,
 *         Jussi Kukkonen
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

using GLib;

// Helper class for BasicManagementTestPing.
internal class Rygel.BasicManagementTestPing : BasicManagementTest {
    private const uint MAX_REPEAT_COUNT = 100;
    private const uint DEFAULT_REPEAT_COUNT = 1;
    private const uint DEFAULT_REPLY_TIMEOUT = 10000;
    private const uint MIN_REQUEST_INTERVAL_TIMEOUT = 1000;
    private const uint MAX_REQUEST_INTERVAL_TIMEOUT = 30000;
    private const uint DEFAULT_REQUEST_INTERVAL_TIMEOUT = 1000;
    private const uint MIN_DATA_BLOCK_SIZE = 20;
    private const uint MAX_DATA_BLOCK_SIZE = 2048;
    private const uint DEFAULT_DATA_BLOCK_SIZE = 32;
    private const uint MAX_DSCP = 64;
    private const uint DEFAULT_DSCP = 30;

    private enum ProcessState {
        INIT,
        STATISTICS,
        RTT,
    }

    private enum Status {
        SUCCESS,
        ERROR_CANNOT_RESOLVE_HOSTNAME,
        ERROR_INTERNAL,
        ERROR_OTHER;

        public string to_string () {
            switch (this) {
                case SUCCESS:
                    return "Success";
                case ERROR_CANNOT_RESOLVE_HOSTNAME:
                    return "Error_CannotResolveHostName";
                case ERROR_INTERNAL:
                    return "Error_Internal";
                case ERROR_OTHER:
                    return "Error_Other";
                default:
                    assert_not_reached ();
            }
        }
    }

    public string host { construct; get; default = ""; }

    private uint _repeat_count = DEFAULT_REPEAT_COUNT;
    public uint repeat_count {
        construct {
            this._repeat_count = value;
            if (this._repeat_count == 0) {
                this._repeat_count = DEFAULT_REPEAT_COUNT;
            }
        }

        get {
            return this._repeat_count;
        }
    }

    private uint _data_block_size = DEFAULT_DATA_BLOCK_SIZE;
    public uint data_block_size {
        construct {
            this._data_block_size = value;
            if (this._data_block_size == 0) {
                this._data_block_size = DEFAULT_DATA_BLOCK_SIZE;
            }
        }

        get {
            return this._data_block_size;
        }
    }

    private uint _dscp = DEFAULT_DSCP;
    public uint dscp {
        construct {
            this._dscp = value;
            if (this._dscp == 0) {
                this._dscp = DEFAULT_DSCP;
            }
        }

        get {
            return this._dscp;
        }
    }

    private uint32 _interval_time_out = DEFAULT_REQUEST_INTERVAL_TIMEOUT;
    public uint32 interval_time_out {
        construct {
            this._interval_time_out = value;
            if (this._interval_time_out == 0) {
                this._interval_time_out = DEFAULT_REQUEST_INTERVAL_TIMEOUT;
            }
        }

        get {
            return _interval_time_out;
        }
    }


    private ProcessState state;
    private Status status;
    private string additional_info;
    private uint success_count;
    private uint failure_count;
    private uint32 avg_response_time;
    private uint32 min_response_time;
    private uint32 max_response_time;

    public override string method_type {
        get {
            return "Ping";
        }
    }

    public override string results_type {
        get {
            return "GetPingResult";
        }
    }

    public BasicManagementTestPing (string host,
                                    uint repeat_count,
                                    uint32 interval_time_out,
                                    uint data_block_size,
                                    uint dscp) {
        Object (host: host,
                repeat_count: repeat_count,
                interval_time_out: interval_time_out,
                data_block_size: data_block_size,
                dscp: dscp);
    }

    public override void constructed () {
        base.constructed ();

        this.status = Status.ERROR_INTERNAL;
        this.state = ProcessState.INIT;
        this.additional_info = "";
        this.success_count = 0;
        this.failure_count = 0;
        this.avg_response_time = 0;
        this.min_response_time = 0;
        this.max_response_time = 0;

        this.command = { "ping",
                         "-c", this.repeat_count.to_string (),
                         "-W", (DEFAULT_REPLY_TIMEOUT / 1000).to_string (),
                         "-i", (this.interval_time_out / 1000).to_string (),
                         "-s", this.data_block_size.to_string (),
                         "-Q", (this.dscp >> 2).to_string (),
                         this.host };

        if (this.repeat_count > MAX_REPEAT_COUNT) {
            this.init_state = InitState.INVALID_PARAMETER;
            this.status = Status.ERROR_OTHER;
            var msg = "NumberOfRepetitions %u is not in allowed range [0, %u]";
            this.additional_info = msg.printf (this.repeat_count,
                                               MAX_REPEAT_COUNT);

        } else if (this.interval_time_out < MIN_REQUEST_INTERVAL_TIMEOUT ||
                   this.interval_time_out > MAX_REQUEST_INTERVAL_TIMEOUT) {
            this.init_state = InitState.INVALID_PARAMETER;
            this.status = Status.ERROR_OTHER;
            var msg = "Timeout %u is not in allowed range [%u, %u]";
            this.additional_info = msg.printf (this.interval_time_out,
                                               MIN_REQUEST_INTERVAL_TIMEOUT,
                                               MAX_REQUEST_INTERVAL_TIMEOUT);

        } else if (this.data_block_size < MIN_DATA_BLOCK_SIZE ||
                   this.data_block_size > MAX_DATA_BLOCK_SIZE) {
            this.init_state = InitState.INVALID_PARAMETER;
            this.status = Status.ERROR_OTHER;
            var msg = "DataBlockSize %u is not in allowed range [%u, %u]";
            this.additional_info = msg.printf (this.data_block_size,
                                               MIN_DATA_BLOCK_SIZE,
                                               MAX_DATA_BLOCK_SIZE);
        } else if (this.dscp > MAX_DSCP) {
            this.init_state = InitState.INVALID_PARAMETER;
            this.status = Status.ERROR_OTHER;
            var msg = "DSCP %u is not in allowed range [0, %u]";
            this.additional_info = msg.printf (this.dscp, MAX_DSCP);
        }
    }

    protected override bool finish_iteration () {
        if (this.init_state == InitState.SPAWN_FAILED) {
            this.status = Status.ERROR_INTERNAL;
            this.additional_info = "Failed to spawn ping";
        }

        return base.finish_iteration ();
    }

    protected override void handle_error (string line) {
        if (line.contains ("ping: unknown host")) {
            this.status = Status.ERROR_CANNOT_RESOLVE_HOSTNAME;
        } else if (line.contains ("ping:")) {
            this.status = Status.ERROR_OTHER;
            this.additional_info = line.substring ("ping:".length).strip ();
        }
    }

    protected override void handle_output (string line) {
        line.strip ();
        if (this.state == ProcessState.INIT) {
            if (line.contains ("statistics ---")) {
                this.state = ProcessState.STATISTICS;
                this.status = Status.SUCCESS;
            }
        } else if (this.state == ProcessState.STATISTICS) {
            if (line.contains ("packets transmitted")) {
                this.state = ProcessState.RTT;

                var rtt_values = line.split (", ", 3);
                uint tx = int.parse (rtt_values[0].split (" ", 3)[0]);
                uint rx = int.parse (rtt_values[1].split (" ", 3)[0]);
                this.failure_count = tx - rx;
                this.success_count = rx;
            }
        } else if (this.state == ProcessState.RTT) {
            if (line.contains ("min/avg/max")) {
                var rtt = line.split ("=", 2);
                if (rtt.length >= 2) {
                    var rtt_values = rtt[1].split ("/", 4);
                    if (rtt_values.length >= 3) {
                        this.min_response_time = (uint) Math.round
                                        (double.parse (rtt_values[0]));
                        this.avg_response_time = (uint) Math.round
                                        (double.parse (rtt_values[1]));
                        this.max_response_time = (uint) Math.round
                                        (double.parse (rtt_values[2]));
                    }
                }
            }
        }
    }

    public void get_results (out string status,
                             out string additional_info,
                             out uint success_count,
                             out uint failure_count,
                             out uint32 avg_response_time,
                             out uint32 min_response_time,
                             out uint32 max_response_time) {
        status = this.status.to_string ();
        additional_info = this.additional_info;
        success_count = this.success_count;
        failure_count = this.failure_count;
        avg_response_time = this.avg_response_time;
        min_response_time = this.min_response_time;
        max_response_time = this.max_response_time;
    }
}
