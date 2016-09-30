/*
 * Copyright (C) 2008-2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

/**
 * Various errors that can be thrown when attempting to seek into a stream.
 *
 * Note: All codes must be set to Soup.Status codes
 */
public errordomain Rygel.HTTPSeekRequestError {
    INVALID_RANGE = Soup.Status.BAD_REQUEST,
    BAD_REQUEST = Soup.Status.BAD_REQUEST,
    OUT_OF_RANGE = Soup.Status.REQUESTED_RANGE_NOT_SATISFIABLE,
}

/**
 * HTTPSeekRequest is an abstract base for a variety of seek request types.
 */
public abstract class Rygel.HTTPSeekRequest : GLib.Object {
    // For designating fields that are unset
    public const int64 UNSPECIFIED = -1;
    // Note: -1 is significant in that libsoup also uses it to designate an "unknown" value
}
