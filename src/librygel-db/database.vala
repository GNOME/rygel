/*
 * Copyright (C) 2009,2011 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

using Sqlite;

namespace Rygel.Database {

    public errordomain DatabaseError {
        SQLITE_ERROR, /// Error code translated from SQLite
        OPEN          /// Error while opening database file
    }

    public enum Flavor {
        CACHE, /// Database is a cache (will be placed in XDG_USER_CACHE
        CONFIG /// Database is configuration (will be placed in XDG_USER_CONFIG)
    }

    public enum Flags {
        READ_ONLY = 1, /// Database is read-only
        WRITE_ONLY = 1 << 1, /// Database is write-only
        /// Database can be read and updated
        READ_WRITE = READ_ONLY | WRITE_ONLY,

        /// Database is shared between several processes
        SHARED = 1 << 2;
    }

    /// Prototype for UTF-8 collation function
    extern static int utf8_collate_str (uint8[] a, uint8[] b);

    /**
     * Special GValue to pass to exec or exec_cursor to bind a column to
     * NULL
     */
    public static GLib.Value @null () {
        GLib.Value v = GLib.Value (typeof (void *));
        v.set_pointer (null);

        return v;
    }
}

/**
 * This class is a thin wrapper around SQLite's database object.
 *
 * It adds statement preparation based on GValue and a cancellable exec
 * function.
 */
public class Rygel.Database.Database : Object {

    /**
     * Function to implement the custom SQL function 'contains'
     */
    public static void utf8_contains (Sqlite.Context context,
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
    public static int utf8_collate (int alen, void* a, int blen, void* b) {
        // unowned to prevent array copy
        unowned uint8[] _a = (uint8[]) a;
        _a.length = alen;

        unowned uint8[] _b = (uint8[]) b;
        _b.length = blen;

        return utf8_collate_str (_a, _b);
    }

    private static string build_path (string name, Flavor flavor) {
        if (name != ":memory:" && !Path.is_absolute (name)) {
            var dirname = Path.build_filename (
                                        flavor == Flavor.CACHE
                                            ? Environment.get_user_cache_dir ()
                                            : Environment.get_user_config_dir (),
                                        "rygel");
            DirUtils.create_with_parents (dirname, 0750);

            return Path.build_filename (dirname, "%s.db".printf (name));
        } else {
            return name;
        }
    }

    private Sqlite.Database db;

    /**
     * Connect to a SQLite database file
     *
     * @param name: Name of the database which is used to create the file-name
     * @param flavor: Specifies the flavor of the database
     * @param flags: How to open the database
     */
    public Database (string name,
                     Flavor flavor = Flavor.CACHE,
                     Flags  flags = Flags.READ_WRITE) throws DatabaseError {
        var path = Database.build_path (name, flavor);
        if (flags == Flags.READ_ONLY) {
            Sqlite.Database.open_v2 (path, out this.db, Sqlite.OPEN_READONLY);
        } else {
            Sqlite.Database.open (path, out this.db);
        }
        if (this.db.errcode () != Sqlite.OK) {
            var msg = _("Error while opening SQLite database %s: %s");
            throw new DatabaseError.OPEN (msg, path, this.db.errmsg ());
        }

        debug ("Using database file %s", path);

        this.exec ("PRAGMA synchronous = OFF");
        this.exec ("PRAGMA count_changes = OFF");

        if (Flags.SHARED in flags) {
            this.exec ("PRAGMA journal_mode = WAL");
        } else {
            this.exec ("PRAGMA temp_store = MEMORY");
        }

        this.db.create_function ("contains",
                                 2,
                                 Sqlite.UTF8,
                                 null,
                                 Database.utf8_contains,
                                 null,
                                 null);

        this.db.create_collation ("CASEFOLD",
                                  Sqlite.UTF8,
                                  Database.utf8_collate);
    }

    /**
     * SQL query function.
     *
     * Use for all queries that return a result set.
     *
     * @param sql The SQL query to run.
     * @param args Values to bind in the SQL query or null.
     * @throws DatabaseError if the underlying SQLite operation fails.
     */
    public Cursor exec_cursor (string        sql,
                                       GLib.Value[]? arguments = null)
                                       throws DatabaseError {
        return new Cursor (this.db, sql, arguments);
    }

    /**
     * Simple SQL query execution function.
     *
     * Use for all queries that don't return anything.
     *
     * @param sql The SQL query to run.
     * @param args Values to bind in the SQL query or null.
     * @throws DatabaseError if the underlying SQLite operation fails.
     */
    public void exec (string        sql,
                      GLib.Value[]? arguments = null)
                      throws DatabaseError {
        var cursor = this.exec_cursor (sql, arguments);
        while (cursor.has_next ()) {
            cursor.next ();
        }
    }

    /**
     * Execute a SQL query that returns a single number.
     *
     * @param sql The SQL query to run.
     * @param args Values to bind in the SQL query or null.
     * @return The contents of the first row's column as an int.
     * @throws DatabaseError if the underlying SQLite operation fails.
     */
    public int query_value (string        sql,
                             GLib.Value[]? args = null)
                             throws DatabaseError {
        var cursor = this.exec_cursor (sql, args);
        var statement = cursor.next ();
        return statement->column_int (0);
    }

    /**
     * Analyze triggers of database
     */
    public void analyze () {
        this.db.exec ("ANALYZE");
    }

    /**
     * Start a transaction
     */
    public void begin () throws DatabaseError {
        this.exec ("BEGIN");
    }

    /**
     * Commit a transaction
     */
    public void commit () throws DatabaseError {
        this.exec ("COMMIT");
    }

    /**
     * Rollback a transaction
     */
    public void rollback () {
        try {
            this.exec ("ROLLBACK");
        } catch (DatabaseError error) {
            critical (_("Failed to roll back transaction: %s"),
                      error.message);
        }
    }
}
