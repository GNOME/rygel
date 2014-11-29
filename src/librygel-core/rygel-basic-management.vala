/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Christophe Guiraud,
 *         Jussi Kukkonen
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

using Gee;
using GLib;
using GUPnP;

/**
 * Basic implementation of UPnP BasicManagement service version 2.
 */
public class Rygel.BasicManagement : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:BasicManagement";
    public const string UPNP_TYPE = "urn:schemas-upnp-org:service:BasicManagement:2";
    public const string DESCRIPTION_PATH = "xml/BasicManagement2.xml";

    public uint max_history_size { get; set; default = 10; }

    private HashMap<string, BasicManagementTest> tests_map;
    private HashMap<string, LinkedList<string>> test_ids_by_type;

    private uint current_id;
    protected string device_status;

    public override void constructed () {
        base.constructed ();

        this.tests_map = new HashMap<string, BasicManagementTest> ();
        this.test_ids_by_type = new HashMap<string, LinkedList> ();

        var now = TimeVal ();
        now.tv_usec = 0;

        this.device_status = "OK," + now.to_iso8601 ();

        this.query_variable["DeviceStatus"].connect
                                        (this.query_device_status_cb);
        this.query_variable["TestIDs"].connect (this.query_test_ids_cb);
        this.query_variable["ActiveTestIDs"].connect
                                        (this.query_active_test_ids_cb);

        this.action_invoked["GetDeviceStatus"].connect
                                        (this.get_device_status_cb);
        this.action_invoked["Ping"].connect (this.ping_cb);
        this.action_invoked["GetPingResult"].connect (this.ping_result_cb);
        this.action_invoked["NSLookup"].connect (this.nslookup_cb);
        this.action_invoked["GetNSLookupResult"].connect
                                        (this.nslookup_result_cb);
        this.action_invoked["Traceroute"].connect (this.traceroute_cb);
        this.action_invoked["GetTracerouteResult"].connect
                                        (this.traceroute_result_cb);
        this.action_invoked["GetTestIDs"].connect (this.get_test_ids_cb);
        this.action_invoked["GetActiveTestIDs"].connect
                                        (this.get_active_test_ids_cb);
        this.action_invoked["GetTestInfo"].connect (this.get_test_info_cb);
        this.action_invoked["CancelTest"].connect (this.cancel_test_cb);
    }

    private string create_test_ids_list (bool active_only) {
        string test_ids_list = "";

        foreach (var test in this.tests_map.values) {
            if (active_only && !test.is_active ()) {
                continue;
            }

            if (test_ids_list.length > 0) {
                test_ids_list += ",";
            }

            test_ids_list += test.id;
        }

        return test_ids_list;
    }

    private string add_test (BasicManagementTest test) {
        this.current_id++;
        test.id = this.current_id.to_string ();

        this.tests_map.set (test.id, test);

        /* Add test to a list of ids of that method type
           (creating the list if needed) */
        LinkedList<string> type_test_ids;
        type_test_ids = this.test_ids_by_type[test.method_type];
        if (type_test_ids == null) {
            type_test_ids = new LinkedList<string> ();
            this.test_ids_by_type.set (test.method_type, type_test_ids);
        }
        type_test_ids.add (test.id);

        /* remove oldest of same type, if needed */
        if (type_test_ids.size > this.max_history_size) {
            var old_id = type_test_ids.poll_head ();

            this.tests_map[old_id].cancellable.cancel ();
            this.tests_map.unset (old_id);
        }

        this.notify ("TestIDs", typeof (string), create_test_ids_list (false));
        this.notify ("ActiveTestIDs",
                     typeof (string),
                     create_test_ids_list (true));

        return test.id;
    }

    private void add_test_and_return_action (BasicManagementTest bm_test,
                                             ServiceAction       action) {
        var id = this.add_test (bm_test);

        /* NOTE: it might be useful queue the execution but this is not
         * currently done: if "BandwidthTest" is implemented queueing is
         * practically required. */
        bm_test.run.begin ((obj,res) => {
            bm_test.run.end (res);
            this.notify ("ActiveTestIDs",
                         typeof (string),
                         create_test_ids_list (true));
        });

        action.set ("TestID", typeof (string), id);

        action.return ();
    }

    private bool ensure_test_exists (ServiceAction           action,
                                     out BasicManagementTest bm_test) {

        string test_id;

        action.get ("TestID", typeof (string), out test_id);

        bm_test = this.tests_map[test_id];
        var action_name = action.get_name ();

        if (bm_test == null) {
            /// No test with the specified TestID was found
            action.return_error (706, _("No Such Test"));

            return false;
        } else if ((bm_test.results_type != action_name) &&
                   ((action_name == "GetPingResult") ||
                    (action_name == "GetNSLookupResult") ||
                    (action_name == "GetTracerouteResult"))) {
            /// TestID is valid but refers to the wrong test type
            action.return_error (707, _("Wrong Test Type"));

            return false;
        } else if ((bm_test.execution_state != BasicManagementTest.ExecutionState.COMPLETED) &&
                   ((action_name == "GetPingResult") ||
                    (action_name == "GetNSLookupResult") ||
                    (action_name == "GetTracerouteResult"))) {
            /// TestID is valid but the test Results are not available
            action.return_error (708, _("Invalid Test State '%s'").printf (
                                        bm_test.execution_state.to_string ()));

            return false;
        } else if ((action_name == "CancelTest") && !bm_test.is_active ()) {
            /// TestID is valid but the test can't be canceled
            action.return_error (709, _("State '%s' Precludes Cancel").printf (
                                        bm_test.execution_state.to_string ()));

            return false;
        }

        return true;
    }

    private void query_device_status_cb (Service   bm,
                                         string    var,
                                         ref Value val) {
        val.init (typeof (string));
        val.set_string (device_status);
    }

    private void query_test_ids_cb (Service   bm,
                                    string    var,
                                    ref Value val) {
        val.init (typeof (string));
        val.set_string (create_test_ids_list (false));
    }

    private void query_active_test_ids_cb (Service   bm,
                                           string    var,
                                           ref Value val) {
        val.init (typeof (string));
        val.set_string (create_test_ids_list (true));
    }

    private void get_device_status_cb (Service       bm,
                                       ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("DeviceStatus",
                        typeof (string),
                        this.device_status);

        action.return ();
    }

    private void ping_cb (Service       bm,
                          ServiceAction action) {
        if (action.get_argument_count () != 5) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        string host;
        uint repeat_count, data_block_size, dscp;
        uint32 interval_time_out;

        action.get ("Host",
                        typeof (string),
                        out host,
                    "NumberOfRepetitions",
                        typeof (uint),
                        out repeat_count,
                    "Timeout",
                        typeof (uint32),
                        out interval_time_out,
                    "DataBlockSize",
                        typeof (uint),
                        out data_block_size,
                    "DSCP",
                        typeof (uint),
                        out dscp);

        if (host == "") {
            warning (_("Cannot run 'Ping' action: Host is empty"));
            action.return_error (402, _("Invalid argument"));

            return;
        }

        var ping = new BasicManagementTestPing (host,
                                                repeat_count,
                                                interval_time_out,
                                                data_block_size,
                                                dscp);
        this.add_test_and_return_action (ping as BasicManagementTest, action);
    }

    private void ping_result_cb (Service       bm,
                                 ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        BasicManagementTest bm_test;

        if (!this.ensure_test_exists (action, out bm_test)) {
            return;
        }

        string status, additional_info;
        uint success_count, failure_count;
        uint32 avg_response_time, min_response_time, max_response_time;

        (bm_test as BasicManagementTestPing).get_results
                                        (out status,
                                         out additional_info,
                                         out success_count,
                                         out failure_count,
                                         out avg_response_time,
                                         out min_response_time,
                                         out max_response_time);

        action.set ("Status",
                        typeof (string),
                        status,
                    "AdditionalInfo",
                        typeof (string),
                        additional_info,
                    "SuccessCount",
                        typeof (uint),
                        success_count,
                    "FailureCount",
                        typeof (uint),
                        failure_count,
                    "AverageResponseTime",
                        typeof (uint32),
                        avg_response_time,
                    "MinimumResponseTime",
                        typeof (uint32),
                        min_response_time,
                    "MaximumResponseTime",
                        typeof (uint32),
                        max_response_time);

        action.return ();
    }

    private void nslookup_cb (Service       bm,
                              ServiceAction action) {
        if (action.get_argument_count () != 4) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        string hostname;
        string dns_server;
        uint repeat_count;
        uint32 interval_time_out;

        action.get ("HostName",
                        typeof (string),
                        out hostname,
                    "DNSServer",
                        typeof (string),
                        out dns_server,
                    "NumberOfRepetitions",
                        typeof (uint),
                        out repeat_count,
                    "Timeout",
                        typeof (uint32),
                        out interval_time_out);

        if (hostname == "") {
            warning (_("Cannot run 'NSLookup' action: HostName is empty"));
            action.return_error (402, _("Invalid argument"));

            return;
        }

        var nslookup = new BasicManagementTestNSLookup (hostname,
                                                        dns_server,
                                                        repeat_count,
                                                        interval_time_out);
        this.add_test_and_return_action (nslookup as BasicManagementTest,
                                         action);
    }

    private void nslookup_result_cb (Service       bm,
                                     ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        BasicManagementTest bm_test;

        if (!this.ensure_test_exists (action, out bm_test)) {
            return;
        }

        string status, additional_info, result;
        uint success_count;

        (bm_test as BasicManagementTestNSLookup).get_results
                                        (out status,
                                         out additional_info,
                                         out success_count,
                                         out result);

        action.set ("Status",
                        typeof (string),
                        status,
                    "AdditionalInfo",
                        typeof (string),
                        additional_info,
                    "SuccessCount",
                        typeof (uint),
                        success_count,
                    "Result",
                        typeof (string),
                        result);

        action.return ();
    }

    private void traceroute_cb (Service       bm,
                                ServiceAction action) {
        if (action.get_argument_count () != 5) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        string host;
        uint32 wait_time_out;
        uint data_block_size, max_hop_count, dscp;

        action.get ("Host",
                        typeof (string),
                        out host,
                    "Timeout",
                        typeof (uint32),
                        out wait_time_out,
                    "DataBlockSize",
                        typeof (uint),
                        out data_block_size,
                    "MaxHopCount",
                        typeof (uint),
                        out max_hop_count,
                    "DSCP",
                        typeof (uint),
                        out dscp);

        if (host == "") {
            warning (_("Cannot run 'Traceroute' action: Host is empty"));
            action.return_error (402, _("Invalid argument"));

            return;
        }

        var traceroute = new BasicManagementTestTraceroute (host,
                                                            wait_time_out,
                                                            data_block_size,
                                                            max_hop_count,
                                                            dscp);
        this.add_test_and_return_action (traceroute as BasicManagementTest,
                                         action);
    }

    private void traceroute_result_cb (Service       bm,
                                       ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        BasicManagementTest bm_test;

        if (!this.ensure_test_exists (action, out bm_test)) {
            return;
        }

        string status, additional_info, hop_hosts;
        uint32 response_time;

        (bm_test as BasicManagementTestTraceroute).get_results
                                        (out status,
                                         out additional_info,
                                         out response_time,
                                         out hop_hosts);

        action.set ("Status",
                        typeof (string),
                        status,
                    "AdditionalInfo",
                        typeof (string),
                        additional_info,
                    "ResponseTime",
                        typeof (uint32),
                        response_time,
                    "HopHosts",
                        typeof (string),
                        hop_hosts);

        action.return ();
    }

    private void get_test_ids_cb (Service       bm,
                                  ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("TestIDs",
                        typeof (string),
                        create_test_ids_list (false));

        action.return ();
    }

    private void get_active_test_ids_cb (Service       bm,
                                         ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("TestIDs",
                        typeof (string),
                        create_test_ids_list (true));

        action.return ();
    }

    private void get_test_info_cb (Service       bm,
                                   ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        BasicManagementTest bm_test;

        if (!this.ensure_test_exists (action, out bm_test)) {
            return;
        }

        action.set ("Type",
                        typeof (string),
                        bm_test.method_type,
                    "State",
                        typeof (string),
                        bm_test.execution_state.to_string ());

        action.return ();
    }

    private void cancel_test_cb (Service       bm,
                                 ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        BasicManagementTest bm_test;

        if (!this.ensure_test_exists (action, out bm_test)) {
            return;
        }

        bm_test.cancellable.cancel ();

        /* ActiveTestIDs notification is handled by
         * the tests' run callback */

        action.return ();
    }
}
