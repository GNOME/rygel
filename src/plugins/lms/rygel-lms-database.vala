/*
 * Copyright (C) 2009,2011 Jens Georg <mail@jensge.org>,
 *           (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

using Rygel;
using Gee;
using Sqlite;

public errordomain Rygel.LMS.DatabaseError {
    OPEN,
    PREPARE,
    BIND,
    STEP,
    NOT_FOUND
}

namespace Rygel.LMS {
    extern static int utf8_collate_str (uint8[] a, uint8[] b);
}

public class Rygel.LMS.Database {

    public signal void db_updated(uint64 old_update_id, uint64 new_update_id);

    private Sqlite.Database db;
    private LMS.DBus lms_proxy;
    private uint64 update_id;

    /**
     * Function to implement the custom SQL function 'contains'
     */
    private static void utf8_contains (Sqlite.Context context,
                                       Sqlite.Value[] args)
                                       requires (args.length == 2) {
        if (args[0].to_text () == null ||
            args[1].to_text () == null) {
           context.result_int (0);

           return;
        }

        var pattern = Regex.escape_string (args[1].to_text ());
        if (Regex.match_simple (pattern,
                                args[0].to_text (),
                                RegexCompileFlags.CASELESS)) {
            context.result_int (1);
        } else {
            context.result_int (0);
        }
    }

    /**
     * Function to implement the custom SQLite collation 'CASEFOLD'.
     *
     * Uses utf8 case-fold to compare the strings.
     */
    private static int utf8_collate (int alen, void* a, int blen, void* b) {
        // unowned to prevent array copy
        unowned uint8[] _a = (uint8[]) a;
        _a.length = alen;

        unowned uint8[] _b = (uint8[]) b;
        _b.length = blen;

        return LMS.utf8_collate_str (_a, _b);
    }

    public Database () throws DatabaseError {
        string db_path;
        try {
            lms_proxy = Bus.get_proxy_sync (BusType.SESSION,
                                            "org.lightmediascanner",
                                            "/org/lightmediascanner/Scanner1");
            db_path = lms_proxy.data_base_path;
            debug ("Got db path %s from LMS over dbus", db_path);
            update_id = lms_proxy.update_id;
            debug ("Got updated id %lld from LMS over dbus", update_id);
            lms_proxy.g_properties_changed.connect (this.on_lms_properties_changed);

        } catch (IOError e) {
            warning("Couldn't get LMS Dbus proxy: %s", e.message);
            db_path = Environment.get_user_config_dir() +
                      "/lightmediascannerd/db.sqlite3";
            debug  ("Using default sqlite database location %s", db_path);
        }

        Sqlite.Database.open (db_path, out this.db);
        if (this.db.errcode () != Sqlite.OK) {
            throw new DatabaseError.OPEN ("Failed to open '%s': %d",
                                          db_path,
                                          this.db.errcode () );
        }

        this.db.create_function ("contains",
                                 2,
                                 Sqlite.UTF8,
                                 null,
                                 LMS.Database.utf8_contains,
                                 null,
                                 null);

        this.db.create_collation ("CASEFOLD",
                                  Sqlite.UTF8,
                                  LMS.Database.utf8_collate);

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


    public Statement prepare (string query_string) throws DatabaseError {
        Statement statement;

        var err = this.db.prepare_v2 (query_string, -1, out statement);
        if (err != Sqlite.OK)
            throw new DatabaseError.PREPARE ("Unable to create statement '%s': %d",
                                             query_string,
                                             err);
        return statement;
    }


    public Statement prepare_and_init (string   query,
                                       GLib.Value[]? arguments)
                                        throws DatabaseError {

        Statement statement;

        var err = this.db.prepare_v2 (query, -1, out statement);
        if (err != Sqlite.OK)
            throw new DatabaseError.PREPARE ("Unable to create statement '%s': %d",
                                             query,
                                             err);

        for (var i = 1; i <= arguments.length; ++i) {
            int sqlite_err;
            unowned GLib.Value current_value = arguments[i - 1];

            if (current_value.holds (typeof (int))) {
                sqlite_err = statement.bind_int (i, current_value.get_int ());
                if (sqlite_err != Sqlite.OK)
                    throw new DatabaseError.BIND("Unable to bind value %d",
                                                 sqlite_err);
            } else if (current_value.holds (typeof (int64))) {
                sqlite_err = statement.bind_int64 (i, current_value.get_int64 ());
                if (sqlite_err != Sqlite.OK)
                    throw new DatabaseError.BIND("Unable to bind value %d",
                                                 sqlite_err);
            } else if (current_value.holds (typeof (uint64))) {
                sqlite_err = statement.bind_int64 (i, (int64) current_value.get_uint64 ());
                if (sqlite_err != Sqlite.OK)
                    throw new DatabaseError.BIND("Unable to bind value %d",
                                                 sqlite_err);
            } else if (current_value.holds (typeof (long))) {
                sqlite_err = statement.bind_int64 (i, current_value.get_long ());
                if (sqlite_err != Sqlite.OK)
                    throw new DatabaseError.BIND("Unable to bind value %d",
                                                 sqlite_err);
            } else if (current_value.holds (typeof (uint))) {
                sqlite_err = statement.bind_int64 (i, current_value.get_uint ());
                if (sqlite_err != Sqlite.OK)
                    throw new DatabaseError.BIND("Unable to bind value %d",
                                                 sqlite_err);
            } else if (current_value.holds (typeof (string))) {
                sqlite_err = statement.bind_text (i, current_value.get_string ());
                if (sqlite_err != Sqlite.OK)
                    throw new DatabaseError.BIND("Unable to bind value %d",
                                                 sqlite_err);
            } else if (current_value.holds (typeof (void *))) {
                if (current_value.peek_pointer () == null) {
                    sqlite_err = statement.bind_null (i);
                    if (sqlite_err != Sqlite.OK)
                        throw new DatabaseError.BIND("Unable to bind value %d",
                                                     sqlite_err);
                } else {
                    assert_not_reached ();
                }
            } else {
                var type = current_value.type ();
                warning (_("Unsupported type %s"), type.name ());
                assert_not_reached ();
            }
        }

        return statement;
    }

    public static void find_object(string id, Statement stmt) throws DatabaseError {

        (void) stmt.reset();

        int integer_id = int.parse(id);
        int sqlite_err = stmt.bind_int(1, integer_id);
        if (sqlite_err != Sqlite.OK)
            throw new DatabaseError.BIND("Unable to bind id %d", sqlite_err);

        sqlite_err = stmt.step();
        if (sqlite_err != Sqlite.ROW)
            throw new DatabaseError.STEP("Unable to find id %s", id);
    }

    public static void get_children_init (Statement stmt,
        uint offset, uint max_count, string sort_criteria) throws DatabaseError {

        int sqlite_err;

        (void) stmt.reset();

        sqlite_err = stmt.bind_int(1, (int) max_count);
        if (sqlite_err != Sqlite.OK)
            throw new DatabaseError.BIND("Unable to bind max_count %d",
                                         sqlite_err);

        sqlite_err = stmt.bind_int(2, (int) offset);
        if (sqlite_err != Sqlite.OK)
            throw new DatabaseError.BIND("Unable to bind offset %d",
                                         sqlite_err);
    }

    public static void get_children_with_update_id_init (Statement stmt,
        uint64 old_id, uint64 new_id) throws DatabaseError {

        int sqlite_err;

        (void) stmt.reset();

        if (new_id < old_id) // id value wrapped over
            sqlite_err = stmt.bind_int64(1, 0);
        else
            sqlite_err = stmt.bind_int64(1, (int64)old_id);
        if (sqlite_err != Sqlite.OK)
            throw new DatabaseError.BIND("Unable to bind old_id %d",
                                         sqlite_err);

        sqlite_err = stmt.bind_int64(2, (int64)new_id);
        if (sqlite_err != Sqlite.OK)
            throw new DatabaseError.BIND("Unable to bind new_id %d",
                                         sqlite_err);
    }

    public static bool get_children_step(Statement stmt) throws DatabaseError {

        bool retval;
        int sqlite_err;

        sqlite_err = stmt.step();
        retval = sqlite_err == Sqlite.ROW;

        if (!retval && (sqlite_err != Sqlite.DONE))
            throw new DatabaseError.STEP("Error iterating through rows %d",
                                         sqlite_err);

        return retval;
    }
}
