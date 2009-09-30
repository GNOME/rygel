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

public errordomain Rygel.DatabaseError {
    SQLITE_ERROR
}

internal class Rygel.Database : Object {
    private Sqlite.Database db;

    public delegate bool RowCallback (Sqlite.Statement stmt);

    public Database(string name) {
        var dirname = Path.build_filename (Environment.get_user_cache_dir (),
                                           "rygel");
        DirUtils.create_with_parents (dirname, 0750);
        var db_file = Path.build_filename (dirname, "%s.db".printf (name));
        debug ("Using database file %s", db_file);
        var rc = Sqlite.Database.open (db_file, out this.db);
        if (rc != Sqlite.OK) {
            warning ("Failed to open database: %d, %s",
                     rc,
                     db.errmsg ());
            return;
        }
        this.db.exec ("PRAGMA cache_size = 32768");
        this.db.exec ("PRAGMA synchronous = OFF");
        this.db.exec ("PRAGMA temp_store = MEMORY");
        this.db.exec ("PRAGMA count_changes = OFF");
    }

    public int exec (string        sql,
                     GLib.Value[]? values   = null,
                     RowCallback?  callback = null) throws DatabaseError {
        var t = new Timer ();
        int rc;

        if (values == null && callback == null) {
            rc = this.db.exec (sql);
        } else {
            var statement = prepare_statement (sql, values);
            while ((rc = statement.step ()) == Sqlite.ROW) {
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
        debug ("Query: %s, Time: %f", sql, t.elapsed ());

        return rc;
    }

    Statement prepare_statement (string sql, GLib.Value[]? values = null)
                                                         throws DatabaseError {
        Statement statement;
        var rc = db.prepare_v2 (sql, -1, out statement, null);
        if (rc != Sqlite.OK)
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());

        if (values != null) {
            for (int i = 0; i < values.length; i++) {
                if (values[i].holds(typeof (int))) {
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
                    warning ("Unsupported type %s", t.name ());
                    assert_not_reached ();
                }
                if (rc != Sqlite.OK) {
                    throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
                }
            }
        }

        return statement;
    }

    // compatibility wrapper for transition
    public weak string errmsg () {
        return this.db.errmsg ();
    }

    public int get_table (string sql, out weak string[] schema_info, out int
        nrows, out int ncolumns, void * foo) {
        weak string[] _schema_info;
        int _nrows;
        int _ncolumns;
        var ret = this.db.get_table (sql,
                                     out _schema_info,
                                     out _nrows,
                                     out _ncolumns,
                                     null);

        schema_info = _schema_info;
        nrows = _nrows;
        ncolumns = _ncolumns;

        return ret;
    }

    public int changes () {
        return this.db.changes ();
    }

    public void analyze () {
        this.db.exec ("ANALYZE");
    }

    public GLib.Value get_null () {
        GLib.Value v = GLib.Value (typeof (void *));
        v.set_pointer (null);
        return v;
    }

    public void begin () throws DatabaseError {
        if (this.db.exec ("BEGIN") != Sqlite.OK) {
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
        }
    }

    public void commit () throws DatabaseError {
        if (this.db.exec ("COMMIT") != Sqlite.OK) {
            throw new DatabaseError.SQLITE_ERROR (db.errmsg ());
        }
    }

    public void rollback () {
        if (this.db.exec ("ROLLBACK") != Sqlite.OK) {
            critical ("Failed to rollback transaction: %s",
                      db.errmsg ());
        }
    }
}
