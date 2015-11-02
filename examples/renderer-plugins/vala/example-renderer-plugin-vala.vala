/*
 * Copyright (C) 2012 Intel Corporation
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

using Rygel;
using GUPnP;

public void module_init (PluginLoader loader) {
    if (loader.plugin_disabled (Rygel.Example.RendererPluginVala.NAME)) {
        message ("Plugin '%s' disabled by user, ignoring..",
                 Rygel.Example.RendererPluginVala.NAME);

        return;
    }

    var plugin = new Rygel.Example.RendererPluginVala ();
    loader.add_plugin (plugin);
}


/*
 * Our derived Plugin class.
 *
 * To use this plugin, you must enable it in your rygel.conf file like so:
 * [ExampleRendererPluginVala]
 * enabled=false
 */
public class Rygel.Example.RendererPluginVala : Rygel.MediaRendererPlugin {
    /*
     * The non-human-readable name for the service:
     * Note that this should currently not contain spaces.
     * See https://bugzilla.gnome.org/show_bug.cgi?id=679673
     */ 
    public const string NAME = "ExampleRendererPluginVala";

    /* Optional human-readable name for the service: */
    public const string TITLE = "Example Renderer Plugin Vala";

    /* Optional human-readable description for the service: */
    public const string DESCRIPTION = "An example Rygel renderer plugin implemented in vala.";

    public RendererPluginVala () {
        base (NAME, TITLE, DESCRIPTION);
    }

    public override void constructed () {
        base.constructed ();
        var l = new List<DLNAProfile> ();
        l.prepend (new DLNAProfile ("JPEG_SM", "image/jpeg"));
        l.prepend (new DLNAProfile ("MP3", "audio/mpeg"));

        this.supported_profiles = l;
    }

    public override MediaPlayer? get_player () {
        return Example.PlayerVala.get_default ();
    }
}
