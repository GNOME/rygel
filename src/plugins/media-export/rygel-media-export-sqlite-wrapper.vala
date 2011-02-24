/*
 * Copyright (C) 2011 Jens Georg <mail@jensge.org>.
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

internal class Rygel.MediaExport.SqliteWrapper : Object {
    private Sqlite.Database database = null;
    private Sqlite.Database *reference = null;

    /**
     * Property to access the wrapped database
     */
    protected unowned Sqlite.Database db {
        get { return reference; }
    }

    /**
     * Wrap an existing SQLite Database object.
     *
     * The SqliteWrapper doesn't take ownership of the passed db
     */
    public SqliteWrapper.wrap (Sqlite.Database db) {
        this.reference = db;
    }

    /**
     * Create or open a new SQLite database in path.
     *
     * @note: Path may also be ":memory:" for temporary databases
     */
    public SqliteWrapper (string path) throws DatabaseError {
        Sqlite.Database.open (path, out this.database);
        this.reference = this.database;
        this.throw_if_db_has_error ();
    }

    /**
     * Convert a SQLite return code to a DatabaseError
     */
    protected void throw_if_code_is_error (int sqlite_error)
                                           throws DatabaseError {
        switch (sqlite_error) {
            case Sqlite.OK:
            case Sqlite.DONE:
            case Sqlite.ROW:
                return;
            default:
                throw new DatabaseError.SQLITE_ERROR
                                        ("SQLite error %d: %s",
                                         sqlite_error,
                                         this.reference->errmsg ());
        }
    }

    /**
     * Check if the last operation on the database was an error
     */
    protected void throw_if_db_has_error () throws DatabaseError {
        this.throw_if_code_is_error (this.reference->errcode ());
    }
}
