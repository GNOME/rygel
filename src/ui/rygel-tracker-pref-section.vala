/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
 *
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
using Gtk;
using Gee;

public class Rygel.TrackerPrefSection : Rygel.PluginPrefSection {
    const string NAME = "Tracker";
    const string VIDEOS_KEY = "share-videos";
    const string MUSIC_KEY = "share-music";
    const string PICTURES_KEY = "share-pictures";
    const string TAG_KEY = "share-tagged";
    const string VIDEOS_CHECK = VIDEOS_KEY + "-checkbutton";
    const string MUSIC_CHECK = MUSIC_KEY + "-checkbutton";
    const string PICTURES_CHECK = PICTURES_KEY + "-checkbutton";

    private CheckButton videos_check;
    private CheckButton music_check;
    private CheckButton pictures_check;

    public TrackerPrefSection (Builder builder, UserConfig config) {
        base (builder, config, NAME);

        this.videos_check = (CheckButton) builder.get_object (VIDEOS_CHECK);
        assert (this.videos_check != null);
        this.music_check = (CheckButton) builder.get_object (MUSIC_CHECK);
        assert (this.music_check != null);
        this.pictures_check = (CheckButton) builder.get_object (PICTURES_CHECK);
        assert (this.pictures_check != null);

        this.videos_check.active = true;
        this.music_check.active = true;
        this.pictures_check.active = true;

        try {
            this.videos_check.active = config.get_bool (this.name, VIDEOS_KEY);
            this.music_check.active = config.get_bool (this.name, MUSIC_KEY);
            this.pictures_check.active = config.get_bool (this.name,
                                                          PICTURES_KEY);
        } catch (Error err) {}
    }

    public override void save () {
        base.save ();

        config.set_bool (this.name, VIDEOS_KEY, this.videos_check.active);
        config.set_bool (this.name, MUSIC_KEY, this.music_check.active);
        config.set_bool (this.name, PICTURES_KEY, this.pictures_check.active);
    }

    protected override void on_enabled_check_toggled (
                                        CheckButton enabled_check) {
        base.on_enabled_check_toggled (enabled_check);

        this.videos_check.sensitive = enabled_check.active;
        this.music_check.sensitive = enabled_check.active;
        this.pictures_check.sensitive = enabled_check.active;
    }
}
