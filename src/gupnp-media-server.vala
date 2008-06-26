/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using GUPnP;
using GConf;
using CStuff;

public class GUPnP.MediaServer: RootDevice {
    public static const string CONTENT_DIR =
                        "urn:schemas-upnp-org:service:ContentDirectory";
    public static const string MEDIA_RECEIVER_REGISTRAR =
                        "urn:microsoft.com:service:X_MS_MediaReceiverRegistrar";

    public static const string DESC_DOC = "xml/description.xml";
    public static const string XBOX_DESC_DOC = "xml/description-xbox360.xml";
    public static const string MODIFIED_DESC_DOC = "gupnp-media-server.xml";
    public static const string GCONF_PATH = "/apps/gupnp-media-server/";

    private ContentDirectory content_dir; /* ContentDirectory */
    private MediaReceiverRegistrar msr;  /* MS MediaReceiverRegistrar */

    construct {
        ResourceFactory factory = this.resource_factory;

        /* Register GUPnP.ContentDirectory */
        factory.register_resource_type (CONTENT_DIR + ":1",
                                        typeof (ContentDirectory));
        factory.register_resource_type (CONTENT_DIR + ":2",
                                        typeof (ContentDirectory));

        /* Register GUPnP.MediaReceiverRegistrar */
        factory.register_resource_type (MEDIA_RECEIVER_REGISTRAR + ":1",
                                        typeof (MediaReceiverRegistrar));
        factory.register_resource_type (MEDIA_RECEIVER_REGISTRAR + ":2",
                                        typeof (MediaReceiverRegistrar));

        /* Now create the sevice objects */
        this.content_dir = (ContentDirectory) this.get_service (CONTENT_DIR);
        this.msr = (MediaReceiverRegistrar) this.get_service
                                                (MEDIA_RECEIVER_REGISTRAR);
    }

    public MediaServer (GUPnP.Context context,
                        Xml.Doc       description_doc,
                        string        relative_location) {
        this.context = context;
        this.resource_factory = GUPnP.ResourceFactory.get_default ();
        this.root_device = null;
        this.description_doc = description_doc;
        this.relative_location = relative_location;
    }

    public static int main (string[] args) {
        MediaServer server;
        MainLoop main_loop;

        server = create_default ();
        if (server == null) {
            return -1;
        }

        main_loop = new GLib.MainLoop (null, false);
        main_loop.run ();

        return 0;
    }

    private static MediaServer? create_default () {
        GConf.Client gconf_client = GConf.Client.get_default ();

        bool enable_xbox;
        try {
            enable_xbox = gconf_client.get_bool (GCONF_PATH + "enable-xbox");
        } catch (GLib.Error error) {
            warning ("%s", error.message);
        }

        /* We store a modified description.xml in the user's config dir */
        string desc_path = Path.build_filename
                                    (Environment.get_user_config_dir (),
                                     MODIFIED_DESC_DOC);

        string orig_desc_path;

        if (enable_xbox)
            /* Use Xbox 360 specific description */
            orig_desc_path = Path.build_filename (BuildConfig.DATA_DIR,
                                                  XBOX_DESC_DOC);
        else
            orig_desc_path = Path.build_filename (BuildConfig.DATA_DIR,
                                                  DESC_DOC);

        Xml.Doc *doc = Xml.Parser.parse_file (orig_desc_path);
        if (doc == null)
            return null;

        /* Modify description.xml to include a UDN and a friendy name */
        set_friendly_name_and_udn (doc, gconf_client);

        if (enable_xbox)
            /* Put/Set XboX specific stuff to description */
            add_xbox_specifics (doc);

        /* Save the modified description.xml into the user's config dir.
         * We do this so that we can host the modified file, and also to
         * make sure the generated UDN stays the same between sessions. */
        FileStream f = FileStream.open (desc_path, "w+");
        int res;

        if (f != null)
            res = Xml.Doc.dump (f, doc);

        if (f == null || res == -1) {
            critical ("Failed to write modified description.xml to %s.\n",
                      desc_path);

            delete doc;

            return null;
        }

        /* Set up GUPnP context */
        GUPnP.Context context = create_default_context (gconf_client,
                                                        desc_path);
        if (context == null) {
            delete doc;

            return null;
        }

        /* Set up the root device */
        MediaServer server = new MediaServer (context,
                                              doc,
                                              MODIFIED_DESC_DOC);

        server.weak_ref ((WeakNotify) xml_doc_free, doc);

        /* Make our device available */
        server.available = true;

        return server;
    }

    private static void xml_doc_free (Xml.Doc* doc, MediaServer server) {
        delete doc;
    }

    private static GUPnP.Context? create_default_context
                                    (GConf.Client gconf_client,
                                     string      desc_path) {
        string host_ip;
        try {
            host_ip = gconf_client.get_string (GCONF_PATH + "host-ip");
        } catch (GLib.Error error) {
            warning ("%s", error.message);

            host_ip = null;
        }

        int port;
        try {
            port = gconf_client.get_int (GCONF_PATH + "port");
        } catch (GLib.Error error) {
            warning ("%s", error.message);

            port = 0;
        }

        GUPnP.Context context;
        try {
            context = new GUPnP.Context (null, host_ip, port);
        } catch (GLib.Error error) {
            warning ("Error setting up GUPnP context: %s", error.message);

            return null;
        }

        /* Host UPnP dir */
        context.host_path (BuildConfig.DATA_DIR, "");

        /* Host our modified file */
        context.host_path (desc_path, "/" + MODIFIED_DESC_DOC);

        return context;
    }

    private static string? get_str_from_gconf (GConf.Client gconf_client,
                                               string       key,
                                               string       default_value) {
        string str;

        try {
            str = gconf_client.get_string (key);
        } catch (GLib.Error error) {
            try {
                gconf_client.set_string (key, str);
            } catch (GLib.Error error) {
                warning ("Error setting gconf key '%s': %s.",
                        key,
                        error.message);

                str = null;
            }
        }

        if (str != null)
                return str;
        else
                return default_value;
    }

    private static void add_xbox_specifics (Xml.Doc doc) {
        Xml.Node *element;

        element = Utils.get_xml_element ((Xml.Node *) doc,
                                         "root",
                                         "device",
                                         "friendlyName");
        /* friendlyName */
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        element->add_content (": 1 : Windows Media Connect");
    }

    /* Fills the description doc @doc with a friendly name, and UDN from gconf.
     * If these keys are not present in gconf, they are set with default values.
     */
    static void set_friendly_name_and_udn (Xml.Doc      doc,
                                           GConf.Client gconf_client) {
        Xml.Node *device_element;
        Xml.Node *element;
        string str, default_value;

        device_element = Utils.get_xml_element ((Xml.Node *) doc,
                                               "root",
                                               "device",
                                               null);
        if (device_element == null) {
            warning ("Element /root/device not found.");

            return;
        }

        /* friendlyName */
        element = Utils.get_xml_element (device_element,
                                         "friendlyName",
                                         null);
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        string user_name = Environment.get_user_name();
        default_value = "%s's GUPnP MediaServer".printf (user_name);
        str = get_str_from_gconf (gconf_client,
                                  GCONF_PATH + "friendly-name",
                                  default_value);
        if (str == null)
            return;

        element->set_content (str);

        /* UDN */
        element = Utils.get_xml_element (device_element, "UDN");
        if (element == null) {
            warning ("Element /root/device/UDN not found.");

            return;
        }

        /* Generate new UUID */
        default_value = Utils.generate_random_udn ();

        str = get_str_from_gconf (gconf_client,
                                  GCONF_PATH + "UDN",
                                  default_value);
        if (str == null)
            return;

        element->set_content (str);
    }
}

