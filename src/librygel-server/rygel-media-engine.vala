/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Craig Pratt <craig@ecaspia.com>
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

public errordomain Rygel.MediaEngineError {
    NOT_FOUND
}

/**
 * This is the base class for media engines that contain knowledge about 
 * the streaming and transformational capabilites of the media library in use.
 *
 * Media engines express what representations of a MediaObject they can
 * produce by returning MediaResource objects which will, in turn, be
 * used to express to endpoints representations can be streamed from
 * the MediaServer. These representations may include transformations,
 * time-scaled representations, and/or encrypted representations.
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
 * See the
 * <link linkend="implementing-media-engines">Implementing Media Engines</link> section.
 */
public abstract class Rygel.MediaEngine : GLib.Object {
    private static MediaEngine instance;

    public static void init () throws Error {
        if (MediaEngine.instance == null) {
            // lazy-load the engine plug-in
            var loader = new EngineLoader ();
            MediaEngine.instance = loader.load_engine ();
            if (MediaEngine.instance == null) {
                throw new MediaEngineError.NOT_FOUND
                    (_("No media engine found."));
            }
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
     * Get a list of the DLNA profiles that the media engine can stream.
     *
     * This information is needed to implement DLNA's
     * ConnectionManager.GetProtocolInfo call and to determine whether Rygel
     * can accept an uploaded file.
     *
     * @return A list of #RygelDLNAProfile<!-- -->s
     */
    public abstract unowned List<DLNAProfile> get_dlna_profiles ();

    /**
     * Retrieve engine-provided resources for the given MediaObject
     *
     * The MediaResources returned may include formats/profiles that do not match the
     * source content byte-for-byte (e.g. transcodes, encrypted formats, etc). The
     * MediaEngine must return a MediaResource for the raw MediaObject content if it
     * can support streaming the content directly.
     *
     * The order of MediaResources in the returned List should be from most-preferred to
     * least-preferred and each must have a unique alphanumeric "name" field.
     *
     * Note: The engine should set all delivery-related flags assuming all delivery forms are
     * supported (e.g. the protocol fields and delivery flags of the ProtocolInfo). And the
     * resource uri should be set to the empty string for http-delivered resources. The
     * effective delivery options and uri will be established by the HTTP server.
     *
     * @return A list of #MediaResources<!-- -->s or null if no representations
     *         are provided by the engine for the item.
     */
    public abstract async Gee.List<MediaResource> ? get_resources_for_item (MediaObject item);

    /**
     * Signaled when one or more #MediaResources<!-- -->s associated with a MediaObject changes.
     * #get_resources_for_item should be called in response to this signal to retrieve the
     * updated list of MediaResources for the associated MediaObject.
     *
     * @param media_object_uri is the uri associated with a MediaObject.=
     */
    public signal void resource_changed (string media_object_uri);

    /**
     * Get a #DataSource for given #MediaResource representation of the #MediaObject.
     *
     * @param item The #MediaObject to create the #DataSource for
     * @param resource The specific resource to create the #DataSource for
     *
     * @return A #DataSource representing the given item resource
     */
    public abstract DataSource? create_data_source_for_resource (MediaObject item,
                                                                 MediaResource resource,
                                                                 HashTable<string, string> replacements)
          throws Error;

    /**
     * Get a #DataSource for the URI.
     *
     * @param uri to create the #DataSource for.
     * @return A #DataSource representing the uri
     */
    public abstract DataSource? create_data_source_for_uri (string uri) throws Error;

    /**
     * Get a list of URI schemes that are internal to the engine.
     *
     * @return A list of strings considered protocol schemees
     */
    public virtual List<string> get_internal_protocol_schemes () {
        return new List<string> ();
    }
}
