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

/**
 * Data class representing a DLNA profile.
 * It contains the name and the corresponding DLNA mime type.
 *
 * Note: The mime type can deviate from mime types typically used elsewhere.
 */
public class Rygel.DLNAProfile {
    public string mime;
    public string name;

    public DLNAProfile (string name, string mime) {
        this.mime = mime;
        this.name = name;
    }

    /**
     * Compare two DLNA profiles by name
     */
    public static int compare_by_name (DLNAProfile a, DLNAProfile b) {
        return a.name.ascii_casecmp (b.name);
    }
}

public errordomain Rygel.MediaEngineError {
    NOT_FOUND
}

/**
 * This is the base class for media engines that contain knowledge about 
 * streaming and transcoding capabilites of the media library in use.
 *
 * See, for instance, Rygel's "gstreamer" and "simple" media engines.
 * The actual media engine used by Rygel at runtime is specified
 * by the media-engine configuration key/
 * For instance, in rygel.conf:
 * media-engine=librygel-media-engine-gst.so
 *
 * Media engines should also derive their own Rygel.DataSource,
 * returning an instance of it from create_data_source().
 */
public abstract class Rygel.MediaEngine : GLib.Object {
    private static MediaEngine instance;

    public static void init () throws Error {
        // lazy-load the engine plug-in
        var loader = new EngineLoader ();
        MediaEngine.instance = loader.load_engine ();
        if (MediaEngine.instance == null) {
            throw new MediaEngineError.NOT_FOUND
                                        (_("No media engine found."));
        }
    }

    /**
     * Get the singleton instance of the currently used media engine.
     *
     * @return An instance of a concrete #MediaEngine implementation.
     */
    public static MediaEngine get_default () {
        if (instance == null) {
            error (_("MediaEngine.init was not called. Cannot continue."));
        }

        return instance;
    }

    /**
     * Get a list of the DLNA profiles that are supported by this media
     * engine.
     *
     * @return A list of #DLNAProfile<!-- -->s
     */
    public abstract unowned List<DLNAProfile> get_dlna_profiles ();

    /**
     * Get a list of the Transcoders that are supported by this media engine.
     *
     * @return A list of #Transcoder<!-- -->s or null if not supported.
     */
    public abstract unowned List<Transcoder>? get_transcoders ();

    /**
     * Get a data source for the URI.
     *
     * @param uri to create the data source for.
     * @return A data source representing the uri
     */
    public abstract DataSource? create_data_source (string uri);
}
