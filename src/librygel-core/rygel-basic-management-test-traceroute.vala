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

// Helper class for BasicManagementTestTraceroute.
internal class Rygel.BasicManagementTestTraceroute : BasicManagementTest {
    private const uint MIN_TIMEOUT = 1000;
    private const uint MAX_TIMEOUT = 30000;
    private const uint DEFAULT_TIMEOUT = 5000;
    private const uint MIN_DATA_BLOCK_SIZE = 20;
    private const uint MAX_DATA_BLOCK_SIZE = 2048;
    private const uint DEFAULT_DATA_BLOCK_SIZE = 32;
    private const uint MAX_DSCP = 64;
    private const uint DEFAULT_DSCP = 30;
    private const uint MAX_HOPS = 64;
    private const uint DEFAULT_HOPS = 30;
    private const uint MAX_HOSTS = 2048;
    private const uint MAX_RESULT_SIZE = 4;

    private enum ProcessState {
        INIT,
        HOPS,
    }

    private enum Status {
        SUCCESS,
        ERROR_CANNOT_RESOLVE_HOSTNAME,
        ERROR_MAX_HOP_COUNT_EXCEEDED,
        ERROR_INTERNAL,
        ERROR_OTHER;

        public string to_string () {
            switch (this) {
                case SUCCESS:
                    return "Success";
                case ERROR_CANNOT_RESOLVE_HOSTNAME:
                    return "Error_CannotResolveHostName";
                case ERROR_MAX_HOP_COUNT_EXCEEDED:
                    return "Error_MaxHopCountExceeded";
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

    private uint32 _wait_time_out = DEFAULT_TIMEOUT;
    public uint32 wait_time_out {
        construct {
            this._wait_time_out = value;
            if (this._wait_time_out == 0) {
                this._wait_time_out = DEFAULT_TIMEOUT;
            }
        }

        get {
            return this._wait_time_out;
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

    private uint _max_hop_count = DEFAULT_HOPS;
    public uint max_hop_count {
        construct {
            this._max_hop_count = value;
            if (this._max_hop_count == 0) {
                this._max_hop_count = DEFAULT_HOPS;
            }
        }

        get {
            return this._max_hop_count;
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

    private Regex regex;
    private Regex rtt_regex;
    private Status status;
    private bool error_set;
    private ProcessState state;
    private string host_ip;
    private string additional_info;
    private uint32 response_time;
    private string hop_ips;

    public override string method_type {
        get {
            return "Traceroute";
        }
    }

    public override string results_type {
        get {
            return "GetTracerouteResult";
        }
    }

    public BasicManagementTestTraceroute (string host,
                                          uint32 wait_time_out,
                                          uint data_block_size,
                                          uint max_hop_count,
                                          uint dscp) {
        Object (host: host,
                wait_time_out: wait_time_out,
                data_block_size: data_block_size,
                max_hop_count: max_hop_count,
                dscp: dscp);
    }

    public override void constructed () {
        base.constructed ();

        try {
            this.regex = new Regex ("^\\s*(\\d+)\\s+(\\S+)\\s*(.*)$", 0, 0);
            this.rtt_regex = new Regex ("(\\S+)\\s+ms\\b", 0, 0);
        } catch (Error e) {
            assert_not_reached ();
        }

        this.state = ProcessState.INIT;
        this.status = Status.ERROR_INTERNAL;
        this.error_set = false;
        this.hop_ips = "";

        this.command = { "traceroute",
                         "-m", this.max_hop_count.to_string (),
                         "-w", (this.wait_time_out / 1000).to_string (),
                         "-t", (this.dscp >> 2).to_string (),
                         "-n",
                         this.host,
                         this.data_block_size.to_string () };

        /* Fail early if internal parameter limits are violated */
        if (this.wait_time_out < MIN_TIMEOUT ||
            this.wait_time_out > MAX_TIMEOUT) {

            this.init_state = InitState.INVALID_PARAMETER;
            var msg = "Timeout %u is not in allowed range [%u, %u]";
            this.additional_info = msg.printf (this.wait_time_out,
                                               MIN_TIMEOUT,
                                               MAX_TIMEOUT);

        } else if (this.data_block_size < MIN_DATA_BLOCK_SIZE ||
                   this.data_block_size > MAX_DATA_BLOCK_SIZE) {
            this.init_state = InitState.INVALID_PARAMETER;
            var msg = "DataBlockSize %u is not in allowed range [%u, %u]";
            this.additional_info = msg.printf (this.data_block_size,
                                               MIN_DATA_BLOCK_SIZE,
                                               MAX_DATA_BLOCK_SIZE);

        } else if (this.max_hop_count > MAX_HOPS) {
            this.init_state = InitState.INVALID_PARAMETER;
            var msg = "MaxHopCount %u is not in allowed range [0, %u]";
            this.additional_info = msg.printf (this.max_hop_count,
                                               MAX_HOPS);

        } else if (this.dscp > MAX_DSCP) {
            this.init_state = InitState.INVALID_PARAMETER;
            var msg = "DSCP %u is not in allowed range [0, %u]";
            this.additional_info = msg.printf (this.dscp, MAX_DSCP);
        }
    }

    private void set_error (Status status, string info) {
        this.error_set = true;
        this.additional_info = info;
        this.status = status;
    }

    protected override void handle_error (string line) {
        if (line.contains ("Cannot handle \"host\" cmdline arg")) {
            this.set_error (Status.ERROR_CANNOT_RESOLVE_HOSTNAME, "");
        } else if (line.contains ("Network is unreachable")) {
            this.set_error (Status.ERROR_OTHER, "Network is unreachable.");
        } else {
            this.set_error (Status.ERROR_INTERNAL, line);
        }
    }

    protected override void handle_output (string line) {
        string error = null;

        line.strip ();
        switch (this.state) {
        case ProcessState.INIT:
            if (line.contains ("traceroute to ")) {
                this.state = ProcessState.HOPS;
                var start = line.index_of_char ('(');
                var end = line.index_of_char (')', start);
                if (end > start) {
                    this.host_ip = line.slice (start + 1, end);
                }
            } else {
                debug ("traceroute parser: Unexpected line '%s'", line);
            }
            break;
        case ProcessState.HOPS:
            if (line.contains (" !H ")) {
                error = "Host is unreachable.";
            } else if (line.contains (" !N ")) {
                error = "Network is unreachable.";
            } else if (line.contains (" !P ")) {
                error = "Protocol is unreachable.";
            } else if (line.contains (" !S ")) {
                error = "Source route failed.";
            } else if (line.contains (" !F ")) {
                error = "Fragmentation needed.";
            } else if (line.contains (" !X ")) {
                error = "Network blocks traceroute.";
            }

            if (error != null) {
                this.set_error (Status.ERROR_OTHER, error);

                return;
            }
            MatchInfo info;
            if (!this.regex.match (line, 0, out info)) {
                debug ("traceroute parser: Unexpected line '%s'", line);

                return;
            }

            var ip_address = info.fetch (2);
            if (!this.error_set) {
                if (ip_address == this.host_ip) {
                    this.status = Status.SUCCESS;
                } else {
                    /* set this error as placeholder: normally a later
                     * handle_output () call will set status to SUCCESS */
                    this.status = Status.ERROR_MAX_HOP_COUNT_EXCEEDED;
                }
            }

            if (ip_address == "*") {
                ip_address = "";
            }

            var rtt_string = info.fetch (3);
            this.rtt_regex.match (rtt_string, 0, out info);
            var rtt_count = 0;
            var rtt_average = 0.0;
            try {
                while (info.matches ()) {
                    rtt_count++;
                    rtt_average += double.parse (info.fetch (1));
                    info.next ();
                }
            } catch (RegexError e) {
                debug ("Failed to parse round trip time values '%s': %s",
                       rtt_string,
                       e.message);
            }

            if (rtt_count > 0) {
                rtt_average = rtt_average / rtt_count;
            }

            this.response_time = (uint) Math.round (rtt_average);
            if (this.hop_ips.length != 0) {
                this.hop_ips += ",";
            }
            this.hop_ips += ip_address;

            break;
       default:
            assert_not_reached ();
        }
    }
    public void get_results (out string status,
                             out string additional_info,
                             out uint32 response_time,
                             out string hop_ips) {
        status = this.status.to_string ();
        additional_info = this.additional_info;
        response_time = this.response_time;
        hop_ips = this.hop_ips;
    }
}
