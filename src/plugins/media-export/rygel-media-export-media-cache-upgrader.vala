/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
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
using Gee;

internal class Rygel.MediaExport.MediaCacheUpgrader {
    private unowned Database database;
    private const string UPDATE_V3_V4_STRING_2 =
    "UPDATE meta_data SET object_fk = " +
        "(SELECT upnp_id FROM Object WHERE metadata_fk = meta_data.id)";

    private const string UPDATE_V3_V4_STRING_3 =
    "ALTER TABLE Object ADD timestamp INTEGER";

    private const string UPDATE_V3_V4_STRING_4 =
    "UPDATE Object SET timestamp = 0";

    public MediaCacheUpgrader (Database database) {
        this.database = database;
    }

    public bool needs_upgrade (out int current_version) throws Error {
        // cannot capture out parameters in closure
        int current_version_temp = 0;

        this.database.exec ("SELECT version FROM schema_info",
                            null,
                            (statement) => {
                                current_version_temp = statement.column_int (0);

                                return false;
                            });
        current_version = current_version_temp;

        return current_version < MediaCache.schema_version.to_int ();
    }

    public void fix_schema () throws Error {
        bool schema_ok = true;

        database.exec ("SELECT count(*) FROM sqlite_master WHERE sql " +
                       "LIKE 'CREATE TABLE Meta_Data%object_fk TEXT " +
                       "UNIQUE%'",
                       null,
                       (statement) => {
                           schema_ok = statement.column_int (0) == 1;

                           return false;
                       });
        if (!schema_ok) {
            try {
                message ("Found faulty schema, forcing full reindex");
                database.begin ();
                database.exec ("DELETE FROM Object WHERE upnp_id IN (" +
                               "SELECT DISTINCT object_fk FROM meta_data)");
                database.exec ("DROP TABLE Meta_Data");
                database.exec (MediaCache.CREATE_META_DATA_TABLE_STRING);
                database.commit ();
            } catch (Error error) {
                database.rollback ();
                warning ("Failed to force reindex to fix database: " +
                        error.message);
            }
        }
    }

    public void upgrade (int old_version) {
        debug ("Older schema detected. Upgrading...");
        int current_version = MediaCache.schema_version.to_int ();
        while (old_version < current_version) {
            if (this.database != null) {
                switch (old_version) {
                    case 3:
                        update_v3_v4 ();
                        break;
                    case 4:
                        update_v4_v5 ();
                        break;
                    case 5:
                        update_v5_v6 ();
                        break;
                    case 6:
                        update_v6_v7 ();
                        break;
                    default:
                        warning ("Cannot upgrade");
                        database = null;
                        break;
                }
                old_version++;
            }
        }
    }

    private void force_reindex () throws DatabaseError {
        database.exec ("UPDATE Object SET timestamp = 0");
    }

    private void update_v3_v4 () {
        try {
            database.begin ();
            database.exec ("ALTER TABLE Meta_Data RENAME TO _Meta_Data");
            database.exec (MediaCache.CREATE_META_DATA_TABLE_STRING);
            database.exec ("INSERT INTO meta_data (size, mime_type, " +
                           "duration, width, height, class, author, album, " +
                           "date, bitrate, sample_freq, bits_per_sample, " +
                           "channels, track, color_depth, object_fk) SELECT " +
                           "size, mime_type, duration, width, height, class, " +
                           "author, album, date, bitrate, sample_freq, " +
                           "bits_per_sample, channels, track, color_depth, " +
                           "o.upnp_id FROM _Meta_Data JOIN object o " +
                           "ON id = o.metadata_fk");
            database.exec ("DROP TABLE _Meta_Data");
            database.exec (UPDATE_V3_V4_STRING_3);
            database.exec (UPDATE_V3_V4_STRING_4);
            database.exec (MediaCache.CREATE_TRIGGER_STRING);
            database.exec ("UPDATE schema_info SET version = '4'");
            database.commit ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    private void update_v4_v5 () {
        Gee.Queue<string> queue = new LinkedList<string> ();
        try {
            database.begin ();
            database.exec ("DROP TRIGGER IF EXISTS trgr_delete_children");
            database.exec (MediaCache.CREATE_CLOSURE_TABLE);
            // this is to have the database generate the closure table
            database.exec ("ALTER TABLE Object RENAME TO _Object");
            database.exec ("CREATE TABLE Object AS SELECT * FROM _Object");
            database.exec ("DELETE FROM Object");
            database.exec (MediaCache.CREATE_CLOSURE_TRIGGER_STRING);
            database.exec ("INSERT INTO _Object (upnp_id, type_fk, title, " +
                           "timestamp) VALUES ('0', 0, 'Root', 0)");
            database.exec ("INSERT INTO Object (upnp_id, type_fk, title, " +
                           "timestamp) VALUES ('0', 0, 'Root', 0)");

            queue.offer ("0");
            while (!queue.is_empty) {
                GLib.Value[] args = { queue.poll () };
                database.exec ("SELECT upnp_id FROM _Object WHERE parent = ?",
                               args,
                               (statement) => {
                                   queue.offer (statement.column_text (0));

                                   return true;
                              });

                database.exec ("INSERT INTO Object SELECT * FROM _OBJECT " +
                               "WHERE parent = ?",
                               args);
            }
            database.exec ("DROP TABLE Object");
            database.exec ("ALTER TABLE _Object RENAME TO Object");
            // the triggers created above have been dropped automatically
            // so we need to recreate them
            database.exec (MediaCache.CREATE_CLOSURE_TRIGGER_STRING);
            database.exec (MediaCache.CREATE_INDICES_STRING);
            database.exec ("UPDATE schema_info SET version = '5'");
            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError err) {
            database.rollback ();
            warning ("Database upgrade failed: %s", err.message);
            database = null;
        }
    }

    private void update_v5_v6 () {
        try {
            database.begin ();
            database.exec ("DROP TABLE object_type");
            database.exec ("ALTER TABLE Object ADD COLUMN uri TEXT");
            database.exec ("UPDATE Object SET uri = (SELECT uri " +
                     "FROM uri WHERE Uri.object_fk == Object.upnp_id LIMIT 1)");
            database.exec ("DROP TRIGGER IF EXISTS trgr_delete_uris");
            database.exec ("DROP INDEX IF EXISTS idx_uri_fk");
            database.exec ("DROP TABLE Uri");
            database.exec ("UPDATE schema_info SET version = '6'");
            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    private void update_v6_v7 () {
        try {
            database.begin ();
            database.exec ("ALTER TABLE meta_data ADD COLUMN dlna_profile TEXT");
            database.exec ("UPDATE schema_info SET version = '7'");
            force_reindex ();
            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }


}
