/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Krzesimir Nowak <krnowak@openismus.com>
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
 * This interface should be implemented by 'updatable' objects - ones
 * that allow modifying their own metadata in some persistent storage.
 */
public interface Rygel.UpdatableObject : MediaObject {
    /**
     * Commit changes in MediaObject to persistent storage.
     *
     * This is called after properties are changed. This happens when
     * e.g. UpdateObject was called on this object.
     */
    public abstract async void commit () throws Error;
}
