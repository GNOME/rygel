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

using GUPnP;
using Xml;

[CCode (cname="TEST_DATA_FOLDER")]
extern const string TEST_DATA_FOLDER;

static const string TARGET =
    "urn:schemas-upnp-org:service:ContentDirectory:3";

public class LastChangeTest : Object {
    private MainLoop loop;
    private ControlPoint cp;
    private ServiceProxy proxy;
    private uint timeout;
    private string lastchange_xsd_file;
    private SchemaValidCtxt *valid_ctxt;
    private Schema *schema;

    ~LastChangeTest () {
        delete this.valid_ctxt;
        delete this.schema;
    }

    private void on_last_change (ServiceProxy p, string variable, Value value) {
        assert (variable == "LastChange");
        var content = value.get_string ();
        var doc = Parser.read_memory (content, content.length);
        assert (doc != null);
        assert (this.valid_ctxt->validate_doc (doc) == 0);
        debug (content);
    }

    private void on_sp_available (ServiceProxy p) {
        this.proxy = p;
        Source.remove (this.timeout);
        debug ("====> Got proxy: %llu", get_real_time ());
        try {
            // Check if the service offers the LastChange state variable
            var last_change = false;
            var introspection = p.get_introspection ();
            unowned List<string> names =
                                    introspection.list_state_variable_names ();
            foreach (var name in names) {
                if (name == "LastChange") {
                    last_change = true;

                    break;
                }
            }
            assert (last_change);
            this.proxy.add_notify ("LastChange",
                                   typeof (string),
                                   this.on_last_change);
            this.proxy.subscribed = true;
        } catch (GLib.Error error) {
            assert_not_reached ();
        }
    }

    private void on_sp_unavailable (ServiceProxy p) {
        if (this.proxy == p) {
            warning ("Proxy disappeared while running the test!");
            assert_not_reached ();
        }
    }

    public int run () {
        this.loop = new MainLoop ();
        this.lastchange_xsd_file = Path.build_filename (TEST_DATA_FOLDER,
                                                        "reference",
                                                        "cds-event-v1.xsd");
        this.schema = new SchemaParserCtxt (this.lastchange_xsd_file).parse ();
        this.valid_ctxt = new SchemaValidCtxt (schema);
        try {
            var context = new Context (null, "lo", 0);
            this.cp = new ControlPoint (context, TARGET);
            this.cp.service_proxy_available.connect (on_sp_available);
            this.cp.service_proxy_unavailable.connect (on_sp_unavailable);
            this.cp.active = true;
            this.timeout = Timeout.add_seconds (10, () => {
                warning ("No suitable server found!");
//                assert_not_reached ();
                return false;
            });
            this.loop.run ();

            return 0;
        } catch (GLib.Error error) {
            print ("Failed to create context: %s\n", error.message);
            assert_not_reached ();
        }
    }

    public static int main (string[] args) {
        var test = new LastChangeTest ();
        return test.run ();
    }
}
