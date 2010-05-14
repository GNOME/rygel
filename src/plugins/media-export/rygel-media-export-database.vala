/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
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

/**
 * This class is a thin wrapper around SQLite's database object.
 *
 * It adds statement preparation based on GValue and a cancellable exec
 * function.
 */
internal class Rygel.MediaExport.Database : Object {
    private Sqlite.Database db;

    /**
     * Callback to pass to exec
     *
     * @return true, if you want the query to continue, false otherwise
     */
    public delegate bool RowCallback (Sqlite.Statement stmt);

    /**
     * Open a database in the user's cache directory as defined by XDG
     *
     * @param name of the database, used to build full path
     * (<cache-dir>/rygel/<name>.db)
     */
    public Database (string name) throws DatabaseError {
        var dirname = Path.build_filename (Environment.get_user_cache_dir (),
                                           "rygel");
        DirUtils.create_with_parents (dirname, 0750);
        var db_file = Path.build_filename (dirname, "%s.db".printf (name));
        debug (_("Using database file %s"), db_file);
        var rc = Sqlite.Database.open (db_file, out this.db);
        if (rc != Sqlite.OK) {
            throw new DatabaseError.IO_ERROR (
                                        _("Failed to open database: %d (%s)"),
                                        rc,
                                        db.errmsg ());
        }

        this.db.exec ("PRAGMA cache_size = 32768");
        this.db.exec ("PRAGMA synchronous = OFF");
        this.db.exec ("PRAGMA temp_store = MEMORY");
        this.db.exec ("PRAGMA count_changes = OFF");
    }

    /**
     * Execute a cancellable SQL statement.
     *
     * The supplied values are bound to the SQL statement and the RowCallback
     * is called on every row of the resultset.
     *
     * @param sql statement to execute
     * @param values array of values to bind to the SQL statement or null if
     * none
     * @param callback to call on each row of the result set or null if none
     * necessary
     * @param cancellable to cancel the running query or null if none
     * necessary
     */
    public int exec (string        sql,
                     GLib.Value[]? values      = null,
                     RowCallback?  callback    = null,
                     Cancellable?  cancellable = null) throws DatabaseError {
        #if RYGEL_DEBUG_SQL
        var t = new Timer ();
        #endif
        int rc;

        if (values == null && callback == null && cancellable == null) {
            rc = this.db.exec (sql);
        } else {
            var statement = prepare_statement (sql, values);
            while ((rc = statement.step ()) == Sqlite.ROW) {
                if (cancellable != null && cancellable.is_cancelled ()) {
                    break;
                }

                if (callback != null) {
                    if (!callback (statement)) {
                        rc = Sqlite.DONE;

                        break;
                    }
                }
            }
        }

        if (rc != Sqlite.DONE && rc != Sqlite.OK) {
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
        }
        #if RYGEL_DEBUG_SQL
        debug ("Query: %s, Time: %f", sql, t.elapsed ());
        #endif

        return rc;
    }

    /**
     * Prepare a SQLite statement from a SQL string
     *
     * This function uses the type of the GValue passed in values to determine
     * which _bind function to use.
     *
     * Supported types are: int, long, int64, string and pointer.
     * @note the only pointer supported is the null pointer as provided by
     * Database.@null. This is a special value to bind a column to NULL
     *
     * @param sql statement to execute
     * @param values array of values to bind to the SQL statement or null if
     * none
     */
    private Statement prepare_statement (string        sql,
                                         GLib.Value[]? values = null)
                                         throws DatabaseError {
        Statement statement;
        var rc = db.prepare_v2 (sql, -1, out statement, null);
        if (rc != Sqlite.OK)
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());

        if (values != null) {
            for (int i = 0; i < values.length; i++) {
                if (values[i].holds (typeof (int))) {
                    rc = statement.bind_int (i + 1, values[i].get_int ());
                } else if (values[i].holds (typeof (int64))) {
                    rc = statement.bind_int64 (i + 1, values[i].get_int64 ());
                } else if (values[i].holds (typeof (long))) {
                    rc = statement.bind_int64 (i + 1, values[i].get_long ());
                } else if (values[i].holds (typeof (string))) {
                    rc = statement.bind_text (i + 1, values[i].get_string ());
                } else if (values[i].holds (typeof (void *))) {
                    if (values[i].peek_pointer () == null) {
                        rc = statement.bind_null (i + 1);
                    } else {
                        assert_not_reached ();
                    }
                } else {
                    var t = values[i].type ();
                    warning (_("Unsupported type %s"), t.name ());
                    assert_not_reached ();
                }
                if (rc != Sqlite.OK) {
                    throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
                }
            }
        }

        return statement;
    }

    /**
     * Analyze triggers of database
     */
    public void analyze () {
        this.db.exec ("ANALYZE");
    }

    /**
     * Special GValue to pass to exec or prepare_statement to bind a column to
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
        if (this.db.exec ("BEGIN") != Sqlite.OK) {
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
        }
    }

    /**
     * Commit a transaction
     */
    public void commit () throws DatabaseError {
        if (this.db.exec ("COMMIT") != Sqlite.OK) {
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
        }
    }

    /**
     * Rollback a transaction
     */
    public void rollback () {
        if (this.db.exec ("ROLLBACK") != Sqlite.OK) {
            critical (_("Failed to roll back transaction: %s"),
                      db.errmsg ());
        }
    }
}
