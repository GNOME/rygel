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
 * This abstract class represents an entity that can contribute response headers to a
 * HTTP request.
 */
public abstract class Rygel.HTTPResponseElement : GLib.Object {
    // For designating fields that are unset
    public const int64 UNSPECIFIED = -1;

    /**
     * Set the type-appropriate headers on the associated HTTP Message
     */
    public abstract void add_response_headers (Rygel.HTTPRequest request);

    public abstract string to_string ();
}
