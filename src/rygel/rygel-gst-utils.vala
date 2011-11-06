/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Gst;

internal errordomain Rygel.GstError {
    MISSING_PLUGIN,
    LINK
}

internal abstract class Rygel.GstUtils {
    public static Element create_element (string factoryname,
                                          string? name)
                                          throws Error {
        Element element = ElementFactory.make (factoryname, name);
        if (element == null) {
            throw new GstError.MISSING_PLUGIN
                                        (_("Required element %s missing"),
                                         factoryname);
        }

        return element;
    }

    public static ClockTime time_from_string (string str) {
        uint64 hours, minutes, seconds;

        str.scanf ("%llu:%2llu:%2llu%*s", out hours, out minutes, out seconds);

        return (ClockTime) ((hours * 3600 + minutes * 60 + seconds) *
                            Gst.SECOND);
    }

    public static string time_to_string (ClockTime time) {
        uint64 hours, minutes, seconds;

        hours   = time / Gst.SECOND / 3600;
        seconds = time / Gst.SECOND % 3600;
        minutes = seconds / 60;
        seconds = seconds % 60;

        return "%llu:%.2llu:%.2llu".printf (hours, minutes, seconds);
    }

    public static Element? create_source_for_uri (string uri) {
        dynamic Element src = Element.make_from_uri (URIType.SRC, uri, null);
        if (src != null) {
            if (src.get_class ().find_property ("blocksize") != null) {
                // The default is usually 4KiB which is not really big enough
                // for most cases so we set this to 65KiB.
                src.blocksize = (long) 65536;
            }

            if (src.get_class ().find_property ("tcp-timeout") != null) {
                // For rtspsrc since some RTSP sources takes a while to start
                // transmitting
                src.tcp_timeout = (int64) 60000000;
            }
        }

        return src;
    }

    public static dynamic Element? get_rtp_depayloader (Caps caps) {
        if (!need_rtp_depayloader (caps)) {
            return null;
        }

        unowned Registry registry = Registry.get_default ();
        var features = registry.feature_filter (rtp_depay_filter, false);

        return get_best_depay (features, caps);
    }

    private static bool need_rtp_depayloader (Caps caps) {
        var structure = caps.get_structure (0);
        return structure.get_name () == "application/x-rtp";
    }

    private static dynamic Element? get_best_depay
                                        (GLib.List<PluginFeature> features,
                                         Caps                     caps) {
        var relevant_factories = new GLib.List<ElementFactory> ();

        // First construct a list of relevant factories
        foreach (PluginFeature feature in features) {
            var factory = (ElementFactory) feature;

            // Skip "rtpdepay" since it's more like a proxy
            if (factory.get_name () == "rtpdepay") {
                continue;
            }

            if (factory.can_sink_any_caps (caps)) {
               relevant_factories.append (factory);
            }
        }

        if (relevant_factories.length () == 0) {
            // No relevant factory available, hence no depayloader
            return null;
        }

        // Then sort the list through their ranks
        relevant_factories.sort (compare_factories);

        // create an element of the top ranking factory and return it
        var factory = relevant_factories.data;

        return ElementFactory.make (factory.get_name (), null);
    }

    private static bool rtp_depay_filter (PluginFeature feature) {
        if (!feature.get_type ().is_a (typeof (ElementFactory))) {
            return false;
        }

        var factory = (ElementFactory) feature;

        return factory.get_klass ().contains ("Depayloader");
    }

    private static int compare_factories (ElementFactory factory_a,
                                          ElementFactory factory_b) {
        return (int) (factory_b.get_rank () - factory_a.get_rank ());
    }
}
