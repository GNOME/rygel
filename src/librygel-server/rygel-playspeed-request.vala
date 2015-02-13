/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLE TELEVISION LABORATORIES
 * INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

public errordomain Rygel.PlaySpeedError {
    INVALID_SPEED_FORMAT,
    SPEED_NOT_PRESENT
}

/**
 * This class represents a DLNA PlaySpeed request (PlaySpeed.dlna.org)
 */
public class Rygel.PlaySpeedRequest : GLib.Object {
    public static const string PLAYSPEED_HEADER = "PlaySpeed.dlna.org";
    public PlaySpeed speed { get; private set; }

    /**
     * Return true if playspeed is supported
     *
     * This method utilizes elements associated with the request to determine if a
     * PlaySpeed request is supported for the given request/resource.
     */
    public static bool supported (HTTPGet request) {
        return request.handler.supports_playspeed ();
    }

    internal static bool requested (HTTPGet request) {
        return request.msg.request_headers.get_one (PLAYSPEED_HEADER) != null;
    }

    public PlaySpeedRequest (int numerator, uint denominator) {
        base ();
        this.speed = new PlaySpeed (numerator, denominator);
    }

    public PlaySpeedRequest.from_string (string speed) throws PlaySpeedError {
        base ();
        this.speed = new PlaySpeed.from_string (speed);
    }

    internal PlaySpeedRequest.from_request (Rygel.HTTPGet request) throws PlaySpeedError {
        base ();
        // Format: PlaySpeed.dlna.org: speed=<rate>
        string speed_string = request.msg.request_headers.get_one (PLAYSPEED_HEADER);

        if (speed_string == null) {
            throw new PlaySpeedError.SPEED_NOT_PRESENT ("Could not find %s",
                                                        PLAYSPEED_HEADER);
        }

        var elements = speed_string.split ("=");

        if ((elements.length != 2) || (elements[0] != "speed")) {
            throw new PlaySpeedError.INVALID_SPEED_FORMAT ("ill-formed value for "
                                                           + PLAYSPEED_HEADER + ": "
                                                           + speed_string );
        }

        speed = new PlaySpeed.from_string (elements[1]);

        // Normal rate is always valid. Just check for valid scaled rate
        if (!speed.is_normal_rate ()) {
            // Validate if playspeed is listed in the protocolInfo
            if (request.handler is HTTPMediaResourceHandler) {
                MediaResource resource = (request.handler as HTTPMediaResourceHandler)
                                         .media_resource;
                var speeds = resource.play_speeds;
                bool found_speed = false;
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
