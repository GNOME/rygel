/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel;
using GUPnP;
using Gee;
using Gst;

public errordomain Rygel.GstStreamError {
    MISSING_PLUGIN,
    LINK
}

public class Rygel.GstStream : Pipeline {
    private const string SINK_NAME = "fakesink";

    public Stream stream;

    private AsyncQueue<Buffer> buffers;

    private Event seek_event;

    public GstStream (Stream  stream,
                      string  name,
                      Element src,
                      Event?  seek_event) throws Error {
        this.stream = stream;
        this.name = name;
        this.seek_event = seek_event;
        this.buffers = new AsyncQueue<Buffer> ();

        this.stream.accept (seek != null);
        this.prepare_pipeline (src);
    }

    private void prepare_pipeline (Element src) throws Error {
        dynamic Element sink = ElementFactory.make ("fakesink", SINK_NAME);

        if (sink == null) {
            throw new GstStreamError.MISSING_PLUGIN ("Required plugin " +
                                                     "'appsink' missing");
        }

        sink.signal_handoffs = true;
        sink.handoff += this.on_new_buffer;

        this.add_many (src, sink);

        if (src.numpads == 0) {
            // Seems source uses dynamic pads, link when pad available
            src.pad_added += this.src_pad_added;
        } else {
            // static pads? easy!
            if (!src.link (sink)) {
                throw new GstStreamError.LINK ("Failed to link %s to %s",
                                               src.name,
                                               sink.name);
            }
        }

        // Bus handler
        var bus = this.get_bus ();
        bus.add_watch (bus_handler);
    }

    private void src_pad_added (Element src,
                                Pad     src_pad) {
        var caps = src_pad.get_caps ();

        var sink = this.get_by_name (SINK_NAME);
        Pad sink_pad;

        dynamic Element depay = this.get_rtp_depayloader (caps);
        if (depay != null) {
            this.add (depay);
            if (!depay.link (sink)) {
                critical ("Failed to link %s to %s",
                          depay.name,
                          sink.name);
            }

            sink_pad = depay.get_compatible_pad (src_pad, caps);
        } else {
            sink_pad = sink.get_compatible_pad (src_pad, caps);
        }

        if (src_pad.link (sink_pad) != PadLinkReturn.OK) {
            critical ("Failed to link pad %s to %s",
                      src_pad.name,
                      sink_pad.name);
            this.stream.end ();
        }

        if (depay != null) {
            depay.sync_state_with_parent ();
        }
    }

    private bool need_rtp_depayloader (Caps caps) {
        var structure = caps.get_structure (0);
        return structure.get_name () == "application/x-rtp";
    }

    private dynamic Element? get_rtp_depayloader (Caps caps) {
        if (!need_rtp_depayloader (caps)) {
            return null;
        }

        unowned Registry registry = Registry.get_default ();
        var features = registry.feature_filter (this.rtp_depay_filter, false);

        return get_best_depay (features, caps);
    }

    private dynamic Element? get_best_depay (GLib.List<PluginFeature> features,
                                             Caps                     caps) {
        var relevant_factories = new GLib.List<ElementFactory> ();

        // First construct a list of relevant factories
        foreach (PluginFeature feature in features) {
            var factory = (ElementFactory) feature;
            if (factory.can_sink_caps (caps)) {
               relevant_factories.append (factory);
            }
        }

        if (relevant_factories.length () == 0) {
            // No relevant factory available, hence no depayloader
            return null;
        }

        // Then sort the list through their ranks
        relevant_factories.sort (this.compare_factories);

        // create an element of the top ranking factory and return it
        var factory = relevant_factories.data;

        return ElementFactory.make (factory.get_name (), null);
    }

    private bool rtp_depay_filter (PluginFeature feature) {
        if (!feature.get_type ().is_a (typeof (ElementFactory))) {
            return false;
        }

        var factory = (ElementFactory) feature;

        return factory.get_klass ().contains ("Depayloader");
    }

    private static int compare_factories (void *a, void *b) {
        ElementFactory factory_a = (ElementFactory) a;
        ElementFactory factory_b = (ElementFactory) b;

        return (int) (factory_b.get_rank () - factory_a.get_rank ());
    }

    private void on_new_buffer (Element sink,
                                Buffer  buffer,
                                Pad     pad) {
        this.buffers.push (buffer);
        Idle.add_full (Priority.HIGH_IDLE, this.idle_handler);
    }

    private bool idle_handler () {
        var buffer = this.buffers.pop ();

        if (buffer != null) {
            this.stream.push_data (buffer.data, buffer.size);
        }

        return false;
    }

    private bool bus_handler (Gst.Bus     bus,
                              Gst.Message message) {
        bool ret = true;

        if (message.type == MessageType.EOS) {
            ret = false;
        } else if (message.type == MessageType.STATE_CHANGED &&
                   this.seek_event != null) {
            State new_state;

            message.parse_state_changed (null, out new_state, null);
            if (new_state == State.PAUSED || new_state == State.PLAYING) {
                // Time to shove-in the pending seek event
                this.send_event (this.seek_event);
                this.seek_event = null;
            }
        } else {
            GLib.Error err;
            string err_msg;

            if (message.type == MessageType.ERROR) {
                message.parse_error (out err, out err_msg);
                critical ("Error from pipeline %s:%s", this.name, err_msg);

                ret = false;
            } else if (message.type == MessageType.WARNING) {
                message.parse_warning (out err, out err_msg);
                warning ("Warning from pipeline %s:%s", this.name, err_msg);
            }
        }

        if (!ret) {
            this.stream.end ();
        }

        return ret;
    }
}

