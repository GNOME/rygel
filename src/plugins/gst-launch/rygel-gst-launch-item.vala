/*
 * Copyright (C) 2009 Thijs Vermeir <thijsvermeir@gmail.com>
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

/**
 * Item that serves data from a gst-launch commandline.
 */
public interface Rygel.GstLaunch.Item : Rygel.MediaItem {
    public abstract string launch_line { get; protected set; }

    protected DataSource? create_source () {
        var engine = MediaEngine.get_default ();

        return engine.create_data_source ("gst-launch://" + this.launch_line);
    }
}

