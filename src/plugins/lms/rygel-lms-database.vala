/*
 * Copyright (C) 2009,2011,2016 Jens Georg <mail@jensge.org>,
 *           (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
 *         Jens Georg <mail@jensge.org>
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

using Rygel;
using Rygel.Database;
using Gee;
using Sqlite;

public class Rygel.LMS.Database : Rygel.Database.Database, Initable {

    public signal void db_updated(uint64 old_update_id, uint64 new_update_id);

    private LMS.DBus lms_proxy;
    private uint64 update_id;

    public Database () throws DatabaseError, Error {
        Object (name: ":memory:", flags : Rygel.Database.Flags.READ_ONLY);
        init ();
    }

    public bool init (Cancellable? cancellable = null) throws Error {
        string db_path;
        try {
            lms_proxy = Bus.get_proxy_sync (BusType.SESSION,
                                            "org.lightmediascanner",
                                            "/org/lightmediascanner/Scanner1");
            db_path = lms_proxy.data_base_path;
            debug ("Got db path %s from LMS over dbus", db_path);
            update_id = lms_proxy.update_id;
            debug ("Got updated id %lld from LMS over dbus", update_id);
            lms_proxy.g_properties_changed.connect
                                        (this.on_lms_properties_changed);
        } catch (IOError e) {
            warning ("Couldn't get LMS Dbus proxy: %s", e.message);
            db_path = Environment.get_user_config_dir () +
                      "/lightmediascannerd/db.sqlite3";
            debug  ("Using default sqlite database location %s", db_path);
        }

        this.name = db_path;

        return base.init ();
    }

    private void on_lms_properties_changed (DBusProxy lms_proxy,
                                        Variant   changed,
                                        string[]  invalidated) {
        if (!changed.get_type().equal (VariantType.VARDICT)) {
            return;
        }

        foreach (var changed_prop in changed) {
            var key = (string) changed_prop.get_child_value (0);
            var value = changed_prop.get_child_value (1).get_child_value (0);

            debug ("LMS property %s changed value to %s", key, value.print(true));

            switch (key) {
                case "UpdateID":
                    db_updated(update_id, (uint64)value);
                    update_id = (uint64)value;
                    break;
            }
        }
    }
}
