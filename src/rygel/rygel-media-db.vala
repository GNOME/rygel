/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Gee;
using Sqlite;

public class Rygel.MediaDB : Object {
    private Database db;
    private const string schema_version = "1";
    private const string db_schema_v1 =
    "BEGIN;" +
    "CREATE TABLE Schema_Info (version TEXT NOT NULL); " +
    "CREATE TABLE Object_Type (id INTEGER PRIMARY KEY, " +
                              "desc TEXT NOT NULL);" +
    "CREATE TABLE Meta_Data (id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                            "size INTEGER NOT NULL, " +
                            "mime_type TEXT NOT NULL, " +
                            "width INTEGER, " +
                            "height INTEGER, " +
                            "class TEXT NOT NULL, " +
                            "title TEXT NOT NULL, " +
                            "author TEXT, " +
                            "album TEXT, " +
                            "date TEXT, " +
                            "bitrate INTEGER, " +
                            "sample_freq INTEGER, " +
                            "bits_per_sample INTEGER, " +
                            "channels INTEGER, " +
                            "track, " +
                            "color_depth);" +
    "CREATE TABLE Object (id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                         "upnp_id TEXT UNIQUE, " +
                         "type_fk INTEGER REFERENCES Object_Type(id), " +
                         "metadata_fk INTEGER REFERENCES Meta_Data(id) " +
                         "ON DELETE CASCADE);" +
    "CREATE TABLE Uri (object_fk INTEGER REFERENCES Object(id), "+
                      "uri TEXT NOT NULL);" +
    "INSERT INTO Object_Type (id, desc) VALUES (0, 'Container'); " +
    "INSERT INTO Object_Type (id, desc) VALUES (1, 'Item'); " +
    "INSERT INTO Schema_Info (version) VALUES ('" + MediaDB.schema_version +
                                                "'); " +
    "END;";


    public MediaDB (string name) {
        var rc = Database.open (name, out this.db);
        if (rc != Sqlite.OK) {
            warning ("Failed to open database: %d, %s",
                     rc,
                     db.errmsg ());
            return;
        }

        weak string[] schema_info;
        int nrows;
        int ncolumns;
        // FIXME error message causes segfaul
        rc = db.get_table ("SELECT version FROM Schema_Info;",
                           out schema_info,
                           out nrows,
                           out ncolumns,
                           null);

        if (rc == Sqlite.OK) {
            if (nrows == 1 && ncolumns == 1) {
                if (schema_info[0] == schema_version) {
                    debug ("Media DB schema has current version");
                } else {
                    debug ("Schema version differs... checking for upgrade");
                    // FIXME implement if necessary
                }
            } else {
                warning ("Incompatible schema... cannot proceed");
                db = null;
                return;
            }
        } else {
            debug ("Could not find schema version; checking for empty database...");
            rc = db.get_table ("SELECT * FROM sqlite_master",
                               out schema_info,
                               out nrows,
                               out ncolumns,
                               null);
            if (rc != Sqlite.OK) {
                warning ("Something weird going on: %s",
                         db.errmsg ());
                db = null;
                return;
            }

            if (nrows == 0) {
                debug ("Empty database, creating new schema version %s",
                       schema_version);
                if (!create_schema ()) {
                    return;
                }
            } else {
                warning ("Incompatible schema... cannot proceed");
                return;
            }
        }
    }

    /**
     * Create the current schema.
     *
     * If schema creation fails, schema will be rolled back
     * completely.
     *
     * @returns: true on success, false on failure
     */
    private bool create_schema () {
        var rc = db.exec (db_schema_v1);
        if (rc == Sqlite.OK) {
            debug ("Schema created");
            return true;
        } else {
            warning ("Could not create schema: %d, %s",
                     rc,
                     db.errmsg ());
            rc = db.exec ("ROLLBACK;");
            return false;
        }
    }
}
