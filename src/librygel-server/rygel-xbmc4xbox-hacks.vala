/*
 * Copyright (C) 2017 Samuel CUELLA
 *
 * Author: Samuel CUELLA <samuel.cuella@supinfo.com>
 * Author: Jens Georg <mail@jensge.org>
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

using Soup;
using GUPnP;


internal class Rygel.XBMC4XBoxHacks : XBMCHacks {

    private const string AGENT = "(.*XBMC.*Xbox.*)|(Platinum/0.5.3.0)";

    public XBMC4XBoxHacks (ServerMessage? message = null) throws ClientHacksError {
        base (message, AGENT);
    }

    public override void apply (MediaObject object) {
        base.apply (object);

        Gee.List<MediaResource> resources = object.get_resource_list ();
        MediaResource primary = resources.first ();

        if (primary == null) {
            return;
        }

        debug ("%s primary resource is %dx%d, %s. DNLA profile is %s",
               object.title,
               primary.width,
               primary.height,
               primary.extension,
               primary.dlna_profile);

        if (!(primary.width > 720 || primary.height > 480 )) {
            return;
        }

        MediaResource? right_one = null;
        foreach (var resource in resources) {
            if (resource.dlna_profile == "MPEG_TS_SD_EU_ISO") {
                right_one = resource;

                break;
            }
        }

        if (right_one != null) {
            //Makes the right_one the first_one, that will be picked
            // up by XBMC4XBOX
            resources.set (0, right_one);
        }
    }
}
