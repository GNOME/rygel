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

/**
 * This class represents a DLNA PlaySpeed response (PlaySpeed.dlna.org)
 */
public class Rygel.PlaySpeedResponse : Rygel.HTTPResponseElement {
    public const string FRAMERATE_HEADER = "FrameRateInTrickMode.dlna.org";

    PlaySpeed speed;
    public const int NO_FRAMERATE = -1;

    /**
     * The framerate supported for the given rate, in frames per second
     */
    public int framerate;

    public PlaySpeedResponse (int numerator, uint denominator, int framerate) {
        base ();
        this.speed = new PlaySpeed (numerator, denominator);
        this.framerate = framerate;
    }

    public PlaySpeedResponse.from_speed (PlaySpeed speed, int framerate)
                                         throws PlaySpeedError {
        base ();
        this.speed = speed;
        this.framerate = framerate;
    }

    public PlaySpeedResponse.from_string (string speed, int framerate)
                                          throws PlaySpeedError {
        base ();
        this.speed = new PlaySpeed.from_string (speed);
        this.framerate = framerate;
    }

    public bool equals (PlaySpeedRequest that) {
        if (that == null) return false;

        return (this.speed.equals (that.speed));
    }

    public override void add_response_headers (Rygel.HTTPRequest request) {
        if (!this.speed.is_normal_rate ()) {
            var headers = request.msg.get_response_headers ();

            // Format: PlaySpeed.dlna.org: speed=<rate>
            headers.append (PlaySpeedRequest.PLAYSPEED_HEADER,
                            "speed=" + this.speed.to_string ());

            if (this.framerate > 0) {
                // Format: FrameRateInTrickMode.dlna.org: rate=<2-digit framerate>
                var framerate_val = "rate=%02d".printf(this.framerate);
                headers.append (FRAMERATE_HEADER, framerate_val);
            }

            if (request.msg.get_http_version () == Soup.HTTPVersion.@1_0) {
                headers.replace ("Pragma", "no-cache");
            }
        }
    }

    public override string to_string () {
        return ("PlaySpeedResponse(speed=%s, framerate=%d)"
                .printf (this.speed.to_string (), this.framerate));
    }
}
