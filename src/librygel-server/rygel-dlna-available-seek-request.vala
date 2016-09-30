/*
 * Copyright (C) 2014  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
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
 * This class represents a DLNA getAvailableSeekRange request.
 *
 * A getAvailableSeekRange request can only have a single parameter: "1"
 */
public class Rygel.DLNAAvailableSeekRangeRequest : Rygel.HTTPSeekRequest {
    public const string GET_AVAILABLE_SEEK_RANGE_HEADER = "getAvailableSeekRange.dlna.org";
    /**
     * Create a DLNAAvailableSeekRangeRequest corresponding with a HTTPGet
     * that contains a getAvailableSeekRange.dlna.org header value.
     *
     * @param request The HTTP GET/HEAD request
     */
    internal DLNAAvailableSeekRangeRequest (Soup.Message message,
                                            Rygel.HTTPGetHandler handler)
                                           throws HTTPSeekRequestError {
        base ();

        var params = message.request_headers.get_one
                                        (GET_AVAILABLE_SEEK_RANGE_HEADER);

        if (params == null) {
            throw new HTTPSeekRequestError.BAD_REQUEST
                                        ("%s not present",
                                         GET_AVAILABLE_SEEK_RANGE_HEADER);
        }
        if (params.strip () != "1") {
            throw new HTTPSeekRequestError.BAD_REQUEST
                                        ("%s != 1 (found \"%s\")",
                                         GET_AVAILABLE_SEEK_RANGE_HEADER,
                                         params);
        }
    }

    /**
     * Return true if getAvailableSeekRange is supported.
     */
    public static bool supported (Soup.Message message,
                                  Rygel.HTTPGetHandler handler) {
        return true;
    }

    /**
     * Return true of the HTTPGet contains a getAvailableSeekRange request.
     */
    public static bool requested (Soup.Message message) {
        return (message.request_headers.get_one (GET_AVAILABLE_SEEK_RANGE_HEADER) != null);
    }
}
