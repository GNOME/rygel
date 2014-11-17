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

public errordomain Rygel.MediaEngineError {
    NOT_FOUND
}

/**
 * This is the base class for media engines that contain knowledge about 
 * the streaming and (optionally) the transcoding and seeking capabilites
 * of the media library in use. Derived classes also instantiate any
 * transcoding objects supported by the media engine and specify the list
 * of media formats the engine is capable of playing.
 *
 * See, for instance, Rygel's built-in "gstreamer" and "simple" media engines,
 * or the external rygel-gst-0-10-media-engine module.
 *
 * The actual media engine used by Rygel at runtime is specified
 * by the media-engine configuration key.
 * For instance, in rygel.conf:
 * media-engine=librygel-media-engine-gst.so
 *
 * Media engines should also derive their own #RygelDataSource,
 * returning an instance of it from create_data_source().
 *
 * If this media engine supports transcoding then it will typically
 * implement a set of transcoding classes, typically with one 
 * base class and a number of sub-classes - one for each transcoding
 * format you want to support. These should be returned by the
 * get_transcoders() virtual function. The base transcoder class could
 * provide a generic way to create a #RygelDataSource capable of
 * providing Rygel with a transcoded version of a file using the
 * underlying media framework. The sub-classes could contain the
 * various media-framework-specific parameters required to 
 * transcode to a given format and implement a heuristic that
 * can be used to order an item's transcoded resources.
 *
 * See the
 * <link linkend="implementing-media-engines">Implementing Media Engines</link> section.
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
     * @return An instance of a concrete #RygelMediaEngine implementation.
     */
    public static MediaEngine get_default () {
        if (instance == null) {
            error (_("MediaEngine.init was not called. Cannot continue."));
        }

        return instance;
    }

    /**
     * Get a list of the DLNA profiles that are supported by this media
     * engine when calling rygel_media_engine_create_data_source().
     *
     * Other DLNA profiles may be supported as transcoding targets -
     *
     * This information is needed to implement DLNA's
     * ConnectionManager.GetProtocolInfo call and to determine whether Rygel
     * can accept an uploaded file.
     *
     * @return A list of #RygelDLNAProfile<!-- -->s
     * @see rygel_media_engine_get_transcoders().
     */
    public abstract unowned List<DLNAProfile> get_dlna_profiles ();

    /**
     * Get a list of the transcoders that are provided by this media engine.
     *
     * @return A list of #RygelTranscoder<!-- -->s or null if not supported.
     */
    public abstract unowned List<Transcoder>? get_transcoders ();

    public virtual DataSource? create_data_source_for_resource
                                        (MediaObject item,
                                         MediaResource resource)
                                         throws Error {
        return this.create_data_source (resource.uri);
    }

    /**
     * Get a data source for the URI.
     *
     * @param uri to create the data source for.
     * @return A data source representing the uri
     */
    public abstract DataSource? create_data_source (string uri);
}
