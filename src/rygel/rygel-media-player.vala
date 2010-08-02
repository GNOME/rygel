/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009,2010 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

public interface Rygel.MediaPlayer : GLib.Object {
    public abstract string playback_state { get; set; }
    public abstract string uri { get; set; }
    public abstract double volume { get; set; }
    public abstract string duration { owned get; }
    public abstract string position { owned get; }

    public abstract bool seek (string time);
    public abstract string[] get_protocols ();
    public abstract string[] get_mime_types ();
}
