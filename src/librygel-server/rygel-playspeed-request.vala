/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Craig Pratt <craig@ecaspia.com>
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

public errordomain Rygel.PlaySpeedError {
    INVALID_SPEED_FORMAT,
    SPEED_NOT_PRESENT
}

/**
 * This class represents a DLNA PlaySpeed request (PlaySpeed.dlna.org)
 */
public class Rygel.PlaySpeedRequest : GLib.Object {
    public const string PLAYSPEED_HEADER = "PlaySpeed.dlna.org";

    public PlaySpeed speed { get; private set; }

    /**
     * Return true if playspeed is supported
     *
     * This method utilizes elements associated with the request to determine
     * if a PlaySpeed request is supported for the given request/resource.
     */
    public static bool supported (HTTPGet request) {
        return request.handler.supports_playspeed ();
    }

    internal static bool requested (HTTPGet request) {
        return request.msg.get_request_headers ().get_one (PLAYSPEED_HEADER) != null;
    }

    public PlaySpeedRequest (int numerator, uint denominator) {
        base ();
        this.speed = new PlaySpeed (numerator, denominator);
    }

    public PlaySpeedRequest.from_string (string speed) throws PlaySpeedError {
        base ();
        this.speed = new PlaySpeed.from_string (speed);
    }

    internal PlaySpeedRequest.from_request (Rygel.HTTPGet request)
                                            throws PlaySpeedError {
        base ();
        // Format: PlaySpeed.dlna.org: speed=<rate>
        string speed_string = request.msg.get_request_headers ().get_one
                                        (PLAYSPEED_HEADER);

        if (speed_string == null) {
            var msg = /*_*/("Could not find playspeed header %s");
            throw new PlaySpeedError.SPEED_NOT_PRESENT (msg, PLAYSPEED_HEADER);
        }

        var elements = speed_string.split ("=");

        if ((elements.length != 2) || (elements[0] != "speed")) {
            var msg = /*_*/("Ill-formed value for header %s: %s");
            throw new PlaySpeedError.INVALID_SPEED_FORMAT (msg,
                                                           PLAYSPEED_HEADER,
                                                           speed_string);
        }

        speed = new PlaySpeed.from_string (elements[1]);

        // Normal rate is always valid. Just check for valid scaled rate
        if (!speed.is_normal_rate ()) {
            // Validate if playspeed is listed in the protocolInfo
            var resource_handler = request.handler as HTTPMediaResourceHandler;

            if (resource_handler != null) {
                var resource = resource_handler.media_resource;
                var speeds = resource.play_speeds;
                var found_speed = false;
                foreach (var speed in speeds) {
                    var cur_speed = new PlaySpeedRequest.from_string (speed);
                    if (this.equals (cur_speed)) {
                        found_speed = true;

                        break;
                    }
                }

                if (!found_speed) {
                    throw new PlaySpeedError
                              .SPEED_NOT_PRESENT ("Unknown playspeed requested (%s)",
                                                  speed_string);
                }
            }
        }
    }

    public bool equals (PlaySpeedRequest that) {
        if (that == null) return false;

        return (this.speed.equals (that.speed));
    }
}
