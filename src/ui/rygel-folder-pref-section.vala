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

public class Rygel.FolderPrefSection : Rygel.PluginPrefSection {
    const string NAME = "Folder";
    const string FOLDERS_KEY = "folders";
    const string FOLDERS_TEXTVIEW = FOLDERS_KEY + "-textview";
    const string FOLDERS_TEXTBUFFER = FOLDERS_KEY + "-textbuffer";

    private TextView text_view;
    private TextBuffer text_buffer;

    public FolderPrefSection (Builder       builder,
                              Configuration config) {
        base (builder, config, NAME);

        this.text_view = (TextView) builder.get_object (FOLDERS_TEXTVIEW);
        assert (this.text_view != null);
        this.text_buffer = (TextBuffer) builder.get_object (FOLDERS_TEXTBUFFER);
        assert (this.text_buffer != null);

        var folders = config.get_string_list (this.name, FOLDERS_KEY);
        string text = "";
        foreach (var folder in folders) {
            text += folder + "\n";
        }
        this.text_buffer.set_text (text, -1);
    }

    public override void save () {
        TextIter start;
        TextIter end;

        this.text_buffer.get_start_iter (out start);
        this.text_buffer.get_end_iter (out end);

        var text = this.text_buffer.get_text (start, end, false);

        var folders = text.split ("\n", -1);
        var folder_list = new ArrayList<string> ();

        foreach (var folder in folders) {
            folder_list.add (folder);
        }

        this.config.set_string_list (this.name, FOLDERS_KEY, folder_list);
    }

    protected override void on_enabled_check_toggled (
                                        CheckButton enabled_check) {
        base.on_enabled_check_toggled (enabled_check);

        this.text_view.sensitive = enabled_check.active;
    }
}
