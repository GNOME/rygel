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

public class Rygel.GeneralPrefSection : PreferencesSection {
    const string IP_ENTRY = "ip-entry";
    const string PORT_SPINBUTTON = "port-spinbutton";
    const string TRANS_CHECKBUTTON = "transcoding-checkbutton";
    const string MP3_CHECKBUTTON = "mp3-checkbutton";
    const string MP2TS_CHECKBUTTON = "mp2ts-checkbutton";
    const string LPCM_CHECKBUTTON = "lpcm-checkbutton";

    private Entry ip_entry;
    private SpinButton port_spin;

    // Transcoding options
    private CheckButton trans_check;
    private CheckButton mp3_check;
    private CheckButton mp2ts_check;
    private CheckButton lpcm_check;

    public GeneralPrefSection (Builder       builder,
                               Configuration config) throws Error {
        base (config, "general");

        this.ip_entry = (Entry) builder.get_object (IP_ENTRY);
        assert (this.ip_entry != null);
        this.port_spin = (SpinButton) builder.get_object (PORT_SPINBUTTON);
        assert (this.port_spin != null);
        this.trans_check = (CheckButton) builder.get_object (TRANS_CHECKBUTTON);
        assert (this.trans_check != null);
        this.mp3_check = (CheckButton) builder.get_object (MP3_CHECKBUTTON);
        assert (this.mp3_check != null);
        this.mp2ts_check = (CheckButton) builder.get_object (MP2TS_CHECKBUTTON);
        assert (this.mp2ts_check != null);
        this.lpcm_check = (CheckButton) builder.get_object (LPCM_CHECKBUTTON);
        assert (this.lpcm_check != null);

        if (config.host_ip != null) {
            this.ip_entry.set_text (config.host_ip);
        }
        this.port_spin.set_value (config.port);

        this.trans_check.active = this.config.transcoding;
        this.mp3_check.active = this.config.mp3_transcoder;
        this.mp2ts_check.active = this.config.mp2ts_transcoder;
        this.lpcm_check.active = this.config.lpcm_transcoder;

        this.trans_check.toggled += this.on_trans_check_toggled;
    }

    public override void save () {
        this.config.host_ip = this.ip_entry.get_text ();
        this.config.port = (int) this.port_spin.get_value ();

        this.config.transcoding = this.trans_check.active;
        this.config.mp3_transcoder = this.mp3_check.active;
        this.config.mp2ts_transcoder = this.mp2ts_check.active;
        this.config.lpcm_transcoder = this.lpcm_check.active;
    }

    private void on_trans_check_toggled (CheckButton trans_check) {
        this.mp3_check.sensitive =
        this.mp2ts_check.sensitive =
        this.lpcm_check.sensitive = trans_check.active;
    }
}
