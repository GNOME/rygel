/*
 * Copyright (C) 2011 Jens Georg
 *
 * Author: Jens Georg <mail@jensge.org>
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

/**
 * Represents a device description document and offers methods for easy
 * manipulation of those.
 */
public class Rygel.DescriptionFile : Object {
    /// XML doc wrapper representing the description document
    private XMLDoc doc;

    // FIXME: Why does //serviceType not work? Seems a bug in libxml2.
    /**
     * XPath template for searching the service type node in
     * modify_service_type()
     */
    private const string SERVICE_TYPE_TEMPLATE = "//*[.='%s']";

    /**
     * Constructor to load a description file from disk
     *
     * @param template the path to the description file.
     * @throws GUPnP.XMLError.PARSE if there was an error reading or parsing
     * the file.
     */
    public DescriptionFile (string template) throws GLib.Error {
        this.doc = new XMLDoc.from_path (template);
    }

    /**
     * Constructor which wraps an existing GUPnP.XMLDoc as a description file.
     *
     * @param doc is the GUPnP.XMLDoc to wrap.
     */
    public DescriptionFile.from_xml_document (XMLDoc doc) {
        this.doc = doc;
    }

    /**
     * Change the type of a service.
     *
     * Usually used to modify the device version, e.g. default device type is
     * "MediaServer:2" and device_type = "MediaServer:1".
     *
     * @param device_type is the current content of serviceType.
     */
    public void set_device_type (string device_type) {
        this.set_device_element ("deviceType", device_type);
    }

    /**
     * Modify the model name.
     *
     * Usually the name of the software implementing this device.
     *
     * @param model_name is the new model name.
     */
    public void set_model_name (string model_name) {
        this.set_device_element ("modelName", model_name);
    }

    /**
     * Modify the model number.
     *
     * Usually the version of the software implementing this device.
     *
     * @param model_number is the new model number.
     */
    public void set_model_number (string model_number) {
        this.set_device_element ("modelNumber", model_number);
    }

    /**
     * Set the friendly name of the device.
     *
     * The friendly name is the one usually presented to the user in control
     * points or DMPs
     *
     * @param friendly_name is the new friendly name of the device.
     */
    public void set_friendly_name (string friendly_name) {
        this.set_device_element ("friendlyName", friendly_name);
    }

    /**
     * Get the current friendly name of the device.
     *
     * @return The currenly set friendly name.
     */
    public string get_friendly_name () {
        var element = Rygel.XMLUtils.get_element ((Xml.Node *) this.doc.doc,
                                                  "root",
                                                  "device",
                                                  "friendlyName");
        assert (element != null);

        return element->get_content ();
    }

    /**
     * Set the DLNA caps of this root device and while taking the
     * capabilities of the plugin into account.
     *
     * @param capabilities RygelPluginCapabilities flags
     */
    public void set_dlna_caps (PluginCapabilities capabilities) {
        var flags = new string[0];
        var content = "";

        if ((PluginCapabilities.UPLOAD & capabilities) != 0) {
            // This means "Supports upload to AnyContainer_DLNA.ORG", but we
            // also use it as "supports upload". AnyContainer upload is
            // handled by Rygel transparently.
            var allow_upload = true;
            var allow_delete = false;

            try {
                var config = MetaConfig.get_default ();
                allow_upload = config.get_allow_upload ();
                allow_delete = config.get_allow_deletion ();
            } catch (GLib.Error error) { }

            if (allow_upload) {
                if (PluginCapabilities.IMAGE_UPLOAD in capabilities) {
                    flags += "image-upload";
                }

                if (PluginCapabilities.VIDEO_UPLOAD in capabilities) {
                    flags += "av-upload";
                }

                if (PluginCapabilities.AUDIO_UPLOAD in capabilities) {
                    flags += "audio-upload";
                }
            }

            if (allow_delete) {
                flags += "create-item-with-OCM-destroy-item";
            }

        }

        // Set the flags we found; otherwise remove whatever is in the
        // template.
        if (flags.length > 0) {
            content = string.joinv (",", flags);
        }

        this.set_device_element ("X_DLNACAP", content);
    }


    /**
     * Change the type of a service.
     *
     * Usually used to modify the service version, e.g. old_type =
     * "ContentDirectory:2" and new_type = "ContentDirectory:1".
     *
     * @param old_type is the current content of serviceType.
     * @param new_type is the content serviceType will be set to.
     */
    public void modify_service_type (string old_type,
                                     string new_type) {
        var context = new XPath.Context (this.doc.doc);

        var xpath = SERVICE_TYPE_TEMPLATE.printf (old_type);
        var xpath_object = context.eval_expression (xpath);
        assert (xpath_object != null);
        assert (xpath_object->type == XPath.ObjectType.NODESET);
        assert (!xpath_object->nodesetval->is_empty ());

        xpath_object->nodesetval->item (0)->set_content (new_type);
    }

    /**
     * Writes the current document to a file.
     *
     * It makes sure that the resulting file has the correct UTF-8 encoding
     * and does not have any kind of newlines. This is necessary as some
     * devices with broken XML parsers can't cope with UNIX newlines.
     * If a file with the same name exists it will be overwritten.
     *
     * @param path is a path to a file.
     * @throws GLib.Error if anything fails while creating the XML dump.
     */
    public void save (string path) throws GLib.Error {
        var file = FileStream.open (path, "w+");
        var message = _("Failed to write modified description to %s");

        if (unlikely (file == null)) {
            throw new IOError.FAILED (message, path);
        }

        string mem = null;
        int len = -1;
        doc.doc.dump_memory_enc (out mem, out len, "UTF-8");

        if (unlikely (len <= 0)) {
            throw new IOError.FAILED (message, path);
        }

        // Make sure we don't have any newlines
        file.puts (mem.replace ("\n", ""));
    }

    /**
     * Internal helper function to set an element to a new value.
     *
     * @param element below /root/device to be set.
     * @param new_vale is the new content of that element.
     */
    private void set_device_element (string element, string new_value) {
        var xml_element = Rygel.XMLUtils.get_element
                                        ((Xml.Node *) this.doc.doc,
                                         "root",
                                         "device",
                                         element);
        if (element != null) {
            xml_element->set_content (new_value);
        }
    }
}
