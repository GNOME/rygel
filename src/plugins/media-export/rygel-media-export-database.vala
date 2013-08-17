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

public errordomain Rygel.MediaExport.DatabaseError {
    IO_ERROR,
    SQLITE_ERROR
}

namespace Rygel.MediaExport {
    extern static int utf8_collate_str (uint8[] a, uint8[] b);
}

/**
 * This class is a thin wrapper around SQLite's database object.
 *
 * It adds statement preparation based on GValue and a cancellable exec
 * function.
 */
internal class Rygel.MediaExport.Database : SqliteWrapper {

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

        return utf8_collate_str (_a, _b);
    }

    /**
     * Open a database in the user's cache directory as defined by XDG
     *
     * @param name of the database, used to build full path
     * (<cache-dir>/rygel/<name>.db)
     */
    public Database (string name) throws DatabaseError {
        string db_file;

        if (name != ":memory:") {
            var dirname = Path.build_filename (
                                        Environment.get_user_cache_dir (),
                                        "rygel");
            DirUtils.create_with_parents (dirname, 0750);
            db_file = Path.build_filename (dirname, "%s.db".printf (name));
        } else {
            db_file = name;
        }

        base (db_file);

        debug ("Using database file %s", db_file);

        this.exec ("PRAGMA synchronous = OFF");
        this.exec ("PRAGMA temp_store = MEMORY");
        this.exec ("PRAGMA count_changes = OFF");

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
    public DatabaseCursor exec_cursor (string        sql,
                                       GLib.Value[]? arguments = null)
                                       throws DatabaseError {
        return new DatabaseCursor (this.db, sql, arguments);
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
        if (arguments == null) {
            this.throw_if_code_is_error (this.db.exec (sql));

            return;
        }

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
     * Special GValue to pass to exec or exec_cursor to bind a column to
     * NULL
     */
    public static GLib.Value @null () {
        GLib.Value v = GLib.Value (typeof (void *));
        v.set_pointer (null);

        return v;
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
