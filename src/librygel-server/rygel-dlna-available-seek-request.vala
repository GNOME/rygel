/*
 * Copyright (C) 2014  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
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

public static const string GET_AVAILABLE_SEEK_RANGE_HEADER = "getAvailableSeekRange.dlna.org";

/**
 * This class represents a DLNA getAvailableSeekRange request.
 *
 * A getAvailableSeekRange request can only have a single parameter: "1"
 */
public class Rygel.DLNAAvailableSeekRangeRequest : Rygel.HTTPSeekRequest {
    /**
     * Create a DLNAAvailableSeekRangeRequest corresponding with a HTTPGet that contains a
     * getAvailableSeekRange.dlna.org header value.
     *
     * @param request The HTTP GET/HEAD request
     */
    internal DLNAAvailableSeekRangeRequest (HTTPGet request)
            throws HTTPSeekRequestError {
        base ();

        var params = request.msg.request_headers.get_one (GET_AVAILABLE_SEEK_RANGE_HEADER);

        if (params == null) {
            throw new HTTPSeekRequestError.BAD_REQUEST ("%s not present",
                                                        GET_AVAILABLE_SEEK_RANGE_HEADER);
        }
        if (params.strip () != "1") {
            throw new HTTPSeekRequestError.BAD_REQUEST ("%s != 1 (found \"%s\")",
                                                        GET_AVAILABLE_SEEK_RANGE_HEADER,
                                                        params);
        }
    }

    /**
     * Return true if getAvailableSeekRange is supported.
     */
    public static bool supported (HTTPGet request) {
        return true;
    }

    /**
     * Return true of the HTTPGet contains a getAvailableSeekRange request.
     */
    public static bool requested (HTTPGet request) {
        return (request.msg.request_headers.get_one (GET_AVAILABLE_SEEK_RANGE_HEADER) != null);
    }
}
