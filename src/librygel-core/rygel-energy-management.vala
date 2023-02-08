/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

/* EnergyManagement service implementation. The service will be run on
 * plugins that have
 *     energy-management=true
 * set in their configuration. It requires UPower to function properly.
 *
 * Every network interface that supports Wake-On should have a
 * configuration group:
 *     [EnergyManagement-eth0]
 *     mode-on-suspend=IP-down-WakeOn
 *     supported-transport=UDP-Broadcast
 *     password=FEEDDEADBEEF
 * mode-on-suspend is required (without it the mode will always be
 * "Unimplemented"), other configuration items are not.
 */


using Gee;
using GLib;
using GUPnP;

[DBus (name = "org.freedesktop.UPower")]
interface UPower : Object {
    public signal void sleeping ();
    public signal void resuming ();
}

/**
 * Implementation of UPnP EnergyManagement service.
 */
public class Rygel.EnergyManagement : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:EnergyManagement";
    public const string UPNP_TYPE = "urn:schemas-upnp-org:service:EnergyManagement:1";
    public const string DESCRIPTION_PATH = "xml/EnergyManagement.xml";

    private const string TEMPLATE = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
                                    "<NetworkInterfaceInfo xsi:schemaLocation=\"urn:schemas-upnp-org:lp:em-NetworkInterfaceInfo http://www.upnp.org/schemas/lp/em-NetworkInterfaceInfo.xsd\" " +
                                    "                      xmlns=\"urn:schemas-upnp-org:lp:em-NetworkInterfaceInfo\" " +
                                    "                      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" +
                                    "%s" +
                                    "</NetworkInterfaceInfo>";

    private Configuration config;
    private bool sleeping;
    private UPower upower;

    public override void constructed () {
        base.constructed ();

        this.config = MetaConfig.get_default ();

        this.sleeping = false;


        try {
            this.upower = Bus.get_proxy_sync
                                        (BusType.SYSTEM,
                                         "org.freedesktop.UPower",
                                         "/org/freedesktop/UPower",
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
            this.upower.sleeping.connect (this.upower_sleeping_cb);
            this.upower.resuming.connect (this.upower_resuming_cb);
        } catch (GLib.IOError err) {
            /* this will lead to NetworkInterfaceMode "Unimplemented" */
        }

        this.query_variable["NetworkInterfaceInfo"].connect
                                        (this.query_network_interface_info_cb);
        this.query_variable["ProxiedNetworkInterfaceInfo"].connect
                                        (this.query_proxied_network_interface_info_cb);

        this.action_invoked["GetInterfaceInfo"].connect
                                        (this.get_interface_info_cb);
    }

    private void upower_sleeping_cb () {
        if (this.sleeping == true) {
            return;
        }

        this.sleeping = true;
        this.notify ("NetworkInterfaceInfo",
                     typeof (string),
                     this.create_network_interface_info ());
    }

    private void upower_resuming_cb () {
        if (this.sleeping == false) {
            return;
        }

        this.sleeping = false;
        this.notify ("NetworkInterfaceInfo",
                     typeof (string),
                     this.create_network_interface_info ());
    }

    extern static bool get_mac_and_network_type (string iface,
                                                 out string mac,
                                                 out string type);

    private string create_network_interface_info () {

        string mac_address, type;
        bool success = true;

        var iface = this.root_device.context.interface;
        var config_section ="EnergyManagement-%s".printf (iface);

        success = EnergyManagement.get_mac_and_network_type (iface, out mac_address, out type);

        var mac = mac_address.replace (":", "");

        var wake_pattern = "FFFFFFFFFFFF%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s".printf (
                                        mac, mac, mac, mac, mac, mac, mac, mac,
                                        mac, mac, mac, mac, mac, mac, mac, mac);
        try {
            var password = this.config.get_string (config_section, "password");
            wake_pattern = wake_pattern.concat (password);
        } catch (GLib.Error error) { }

        var ip_addr = this.root_device.context.address;
        bool is_ipv6 = (ip_addr != null && ip_addr.family == SocketFamily.IPV6);
        var associated_ips = "<Ipv%d>%s</Ipv%d>".printf
                                        (is_ipv6 ? 6 : 4,
                                         ip_addr.to_string(),
                                         is_ipv6 ? 6 : 4);

        string mode;
        if (!success || this.upower == null) {
            mode = "Unimplemented";
        } else {
            try {
                /* Note: we want to check the value exists even when not sleeping */
                var sleep_mode = this.config.get_string (config_section,
                                                         "mode-on-suspend");
                mode = this.sleeping ? sleep_mode : "IP-up";
            } catch (GLib.Error error) {
                mode = "Unimplemented";
            }
        }

        string transport_node;
        try {
            var val = this.config.get_string (config_section,
                                              "supported-transport");
            transport_node = "<WakeSupportedTransport>%s</WakeSupportedTransport>".printf
                                        (val);
        } catch (GLib.Error error) {
            transport_node = "";
        }

        var device_info = ("<DeviceInterface>" +
                           "<DeviceUUID>%s</DeviceUUID>" +
                           "<FriendlyName>%s</FriendlyName>" +
                           "<NetworkInterface>" +
                           "<SystemName>%s</SystemName>" +
                           "<MacAddress>%s</MacAddress>" +
                           "<InterfaceType>%s</InterfaceType>" +
                           "<NetworkInterfaceMode>%s</NetworkInterfaceMode>" +
                           "<AssociatedIpAddresses>%s</AssociatedIpAddresses>" +
                           "<WakeOnPattern>%s</WakeOnPattern>" +
                           "%s" +
                           "</NetworkInterface>" +
                           "</DeviceInterface>").printf
                                        (this.root_device.udn,
                                         this.root_device.get_friendly_name (),
                                         iface,
                                         mac_address,
                                         type,
                                         mode,
                                         associated_ips,
                                         wake_pattern,
                                         transport_node);

        return TEMPLATE.printf (device_info);
    }

    private string create_proxied_network_interface_info () {
        /* No proxy support: Return empty NetworkInterfaceInfo */

        return TEMPLATE.printf ("");
    }

    private void query_network_interface_info_cb (Service   em,
                                                  string    var,
                                                  ref Value val) {
        val.init (typeof (string));
        val.set_string (this.create_network_interface_info ());
    }

    private void query_proxied_network_interface_info_cb (Service   em,
                                                          string    var,
                                                          ref Value val) {
        val.init (typeof (string));
        val.set_string (this.create_proxied_network_interface_info ());
    }

    private void get_interface_info_cb (Service       em,
                                        ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("NetworkInterfaceInfo",
                    typeof (string),
                    this.create_network_interface_info ());

        action.set ("ProxiedNetworkInterfaceInfo",
                    typeof (string),
                    this.create_proxied_network_interface_info ());

        action.return_success ();
    }
}
