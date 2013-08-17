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
    private unowned SQLFactory sql;

    private const string UPDATE_V3_V4_STRING_2 =
    "UPDATE meta_data SET object_fk = " +
        "(SELECT upnp_id FROM Object WHERE metadata_fk = meta_data.id)";

    private const string UPDATE_V3_V4_STRING_3 =
    "ALTER TABLE Object ADD timestamp INTEGER";

    private const string UPDATE_V3_V4_STRING_4 =
    "UPDATE Object SET timestamp = 0";

    public MediaCacheUpgrader (Database database, SQLFactory sql) {
        this.database = database;
        this.sql = sql;
    }

    public bool needs_upgrade (out int current_version) throws Error {
        current_version = this.database.query_value (
                                        "SELECT version FROM schema_info");

        return current_version < int.parse (SQLFactory.SCHEMA_VERSION);
    }

    public void fix_schema () throws Error {
        var matching_schema_count = this.database.query_value (
                                        "SELECT count(*) FROM " +
                                        "sqlite_master WHERE sql " +
                                        "LIKE 'CREATE TABLE Meta_Data" +
                                        "%object_fk TEXT UNIQUE%'");
        if (matching_schema_count == 0) {
            try {
                message ("Found faulty schema, forcing full reindex");
                database.begin ();
                database.exec ("DELETE FROM Object WHERE upnp_id IN (" +
                               "SELECT DISTINCT object_fk FROM meta_data)");
                database.exec ("DROP TABLE Meta_Data");
                database.exec (this.sql.make (SQLString.TABLE_METADATA));
                database.commit ();
            } catch (Error error) {
                database.rollback ();
                warning ("Failed to force reindex to fix database: " +
                        error.message);
            }
        }
    }

    public void ensure_indices () {
        try {
            this.database.exec (this.sql.make (SQLString.INDEX_COMMON));
            this.database.analyze ();
        } catch (Error error) {
            warning ("Failed to create indices: " +
                     error.message);
        }
    }

    public void upgrade (int old_version) {
        debug ("Older schema detected. Upgrading...");
        int current_version = int.parse (SQLFactory.SCHEMA_VERSION);
        while (old_version < current_version) {
            if (this.database == null) {
                break;
            }

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
                case 7:
                    update_v7_v8 ();
                    break;
                case 8:
                    update_v8_v9 ();
                    break;
                case 9:
                    update_v9_v10 ();
                    break;
                case 10:
                    update_v10_v11 ();
                    break;
                case 11:
                    update_v11_v12 ();
                    break;
                case 12:
                    update_v12_v13 ();
                    break;
                case 13:
                    this.update_v13_v14 ();
                    break;
                case 14:
                    this.update_v14_v15 ();
                    break;
                case 15:
                    this.update_v15_v16 ();
                    break;
                default:
                    warning ("Cannot upgrade");
                    database = null;
                    break;
            }
            old_version++;
        }
    }

    private void force_reindex () throws DatabaseError {
        database.exec ("UPDATE Object SET timestamp = 0");
    }

    private void update_v3_v4 () {
        try {
            database.begin ();
            database.exec ("ALTER TABLE Meta_Data RENAME TO _Meta_Data");
            database.exec (this.sql.make (SQLString.TABLE_METADATA));
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
            database.exec (this.sql.make (SQLString.TRIGGER_COMMON));
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
            database.exec (this.sql.make (SQLString.TABLE_CLOSURE));
            // this is to have the database generate the closure table
            database.exec ("ALTER TABLE Object RENAME TO _Object");
            database.exec ("CREATE TABLE Object AS SELECT * FROM _Object");
            database.exec ("DELETE FROM Object");
            database.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            database.exec ("INSERT INTO _Object (upnp_id, type_fk, title, " +
                           "timestamp) VALUES ('0', 0, 'Root', 0)");
            database.exec ("INSERT INTO Object (upnp_id, type_fk, title, " +
                           "timestamp) VALUES ('0', 0, 'Root', 0)");

            queue.offer ("0");
            while (!queue.is_empty) {
                GLib.Value[] args = { queue.poll () };
                var cursor = this.database.exec_cursor (
                                        "SELECT upnp_id FROM _Object WHERE " +
                                        "parent = ?",
                                        args);
                foreach (var statement in cursor) {
                    queue.offer (statement.column_text (0));
                }

                database.exec ("INSERT INTO Object SELECT * FROM _OBJECT " +
                               "WHERE parent = ?",
                               args);
            }
            database.exec ("DROP TABLE Object");
            database.exec ("ALTER TABLE _Object RENAME TO Object");
            // the triggers created above have been dropped automatically
            // so we need to recreate them
            database.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            database.exec (this.sql.make (SQLString.INDEX_COMMON));
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
            database.exec ("DROP TRIGGER IF EXISTS trgr_delete_uris");
            database.exec ("ALTER TABLE Object ADD COLUMN uri TEXT");
            database.exec ("UPDATE Object SET uri = (SELECT uri " +
                     "FROM uri WHERE Uri.object_fk == Object.upnp_id LIMIT 1)");
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

    private void update_v7_v8 () {
        try {
            database.begin ();
            database.exec ("ALTER TABLE object ADD COLUMN flags TEXT");
            database.exec ("ALTER TABLE meta_data ADD COLUMN genre TEXT");
            database.exec ("UPDATE schema_info SET version = '8'");
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

    private void update_v8_v9 () {
        try {
            this.database.begin ();
            this.database.exec ("DROP TRIGGER trgr_update_closure");
            this.database.exec ("DROP TRIGGER trgr_delete_closure");
            this.database.exec ("ALTER TABLE Closure RENAME TO _Closure");
            this.database.exec (this.sql.make (SQLString.TABLE_CLOSURE));
            this.database.exec ("INSERT INTO Closure (ancestor, " +
                                "descendant, depth) SELECT DISTINCT " +
                                "ancestor, descendant, depth FROM " +
                                "_Closure");
            this.database.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            this.database.exec ("DROP TABLE _Closure");
            this.database.exec ("UPDATE schema_info SET version = '9'");
            this.database.commit ();
            this.database.exec ("VACUUM");
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    // This isn't really a schema update but a semantics update
    private void update_v9_v10 () {
        try {
            var queue = new LinkedList<string> ();
            this.database.begin ();
            this.database.exec ("DELETE FROM Object WHERE upnp_id LIKE '" +
                                QueryContainer.PREFIX + "%'");
            this.database.exec ("DROP TRIGGER trgr_update_closure");
            this.database.exec ("DROP TRIGGER trgr_delete_closure");
            this.database.exec ("DROP INDEX idx_parent");
            this.database.exec ("DROP INDEX idx_meta_data_fk");
            this.database.exec ("DROP INDEX IF EXISTS idx_closure");
            this.database.exec ("DROP TABLE Closure");

            // keep meta-data although we're deleting loads of objects
            this.database.exec ("DROP TRIGGER trgr_delete_metadata");

            this.database.exec ("INSERT OR REPLACE INTO Object (parent, upnp_id, " +
                                "type_fk, title, timestamp) VALUES " +
                                "('0', '" +
                                RootContainer.FILESYSTEM_FOLDER_ID +
                                "', 0, '" +
                                _(RootContainer.FILESYSTEM_FOLDER_NAME) +
                                "', 0)");
            this.database.exec ("UPDATE Object SET parent = '" +
                                RootContainer.FILESYSTEM_FOLDER_ID +
                                "' WHERE parent = '0' AND upnp_id " +
                                "NOT LIKE 'virtual-%' AND upnp_id " +
                                "<> '" +
                                RootContainer.FILESYSTEM_FOLDER_ID +
                                "'");
            this.database.exec ("ALTER TABLE Object RENAME TO _Object");
            this.database.exec ("CREATE TABLE Object AS SELECT * FROM _Object");
            this.database.exec ("DELETE FROM Object");
            this.database.exec (this.sql.make (SQLString.TABLE_CLOSURE));
            this.database.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            this.database.exec ("INSERT INTO Closure (ancestor, descendant, " +
                                "depth) VALUES ('0','0',0)");
            queue.offer ("0");
            while (!queue.is_empty) {
                GLib.Value[] args = { queue.poll () };
                var cursor = this.database.exec_cursor (
                                        "SELECT upnp_id FROM _Object WHERE " +
                                        "parent = ?",
                                        args);
                foreach (var statement in cursor) {
                    queue.offer (statement.column_text (0));
                }

                database.exec ("INSERT INTO Object SELECT * FROM _Object " +
                               "WHERE parent = ?",
                               args);
            }
            database.exec ("DROP TABLE Object");
            this.database.exec ("ALTER TABLE _Object RENAME TO Object");
            database.exec (this.sql.make (SQLString.INDEX_COMMON));
            database.exec (this.sql.make (SQLString.TRIGGER_COMMON));
            this.database.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            database.exec ("UPDATE schema_info SET version = '10'");
            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    private void update_v10_v11 () {
        try {
            this.database.begin ();
            this.database.exec ("ALTER TABLE Meta_Data " +
                                "   ADD COLUMN disc INTEGER");
            // Force reindexing of audio data to get disc number
            this.database.exec ("UPDATE Object SET timestamp = 0 WHERE " +
                                "  upnp_id IN (" +
                                "SELECT object_fk FROM Meta_Data WHERE " +
                                "  class LIKE 'object.item.audioItem.%')");
            this.database.exec ("UPDATE schema_info SET version = '11'");
            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    private void update_v11_v12 () {
        try {
            this.database.begin ();
            this.database.exec ("ALTER TABLE schema_info " +
                                "ADD COLUMN reset_token TEXT");
            this.database.exec ("UPDATE schema_info SET reset_token = '" +
                                UUID.get () + "'");
            this.database.exec ("UPDATE schema_info SET version = '12'");
            this.database.exec ("ALTER TABLE object " +
                                "ADD COLUMN object_update_id INTEGER");
            this.database.exec ("ALTER TABLE object " +
                                "ADD COLUMN deleted_child_count INTEGER");
            this.database.exec ("ALTER TABLE object " +
                                "ADD COLUMN container_update_id INTEGER");
            var ids = new ArrayList<string> ();
            var cursor = this.database.exec_cursor
                                        ("SELECT upnp_id FROM object");
            foreach (var statement in cursor) {
                ids.add (statement.column_text (0));
            }

            uint32 count = 1;
            foreach (var id in ids) {
                GLib.Value[] args = { count, count, id };
                count++;
                this.database.exec ("UPDATE object SET " +
                                    "container_update_id = ?, " +
                                    "object_update_id = ?, " +
                                    "deleted_child_count = 0 " +
                                    "WHERE upnp_id = ?",
                                    args);
            }

            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    private void update_v12_v13 () {
        try {
            this.database.begin ();
            this.database.exec ("CREATE TEMPORARY TABLE object_backup(parent TEXT CONSTRAINT parent_fk_id " +
                                "REFERENCES Object(upnp_id), " +
                                "upnp_id TEXT PRIMARY KEY, " +
                                "type_fk INTEGER, " +
                                "title TEXT NOT NULL, " +
                                "timestamp INTEGER NOT NULL, " +
                                "uri TEXT, " +
                                "object_update_id INTEGER, " +
                                "deleted_child_count INTEGER, " +
                                "container_update_id INTEGER)");
            this.database.exec ("INSERT INTO object_backup SELECT " +
                                "parent, upnp_id, type_fk, title, " +
                                "timestamp, uri, object_update_id, " +
                                "deleted_child_count, container_update_id " +
                                "FROM object");
            this.database.exec ("DROP TRIGGER IF EXISTS trgr_update_closure");
            this.database.exec ("DROP TRIGGER IF EXISTS trgr_delete_closure");
            this.database.exec ("DROP TRIGGER IF EXISTS trgr_delete_metadata");
            this.database.exec ("DROP INDEX IF EXISTS idx_parent");
            this.database.exec ("DROP INDEX IF EXISTS idx_object_upnp_id");
            this.database.exec ("DROP INDEX IF EXISTS idx_uri");
            this.database.exec ("DROP TABLE object");
            this.database.exec ("CREATE TABLE object " +
                                "(parent TEXT CONSTRAINT parent_fk_id " +
                                "REFERENCES Object(upnp_id), " +
                                "upnp_id TEXT PRIMARY KEY, " +
                                "type_fk INTEGER, " +
                                "title TEXT NOT NULL, " +
                                "timestamp INTEGER NOT NULL, " +
                                "uri TEXT, " +
                                "object_update_id INTEGER, " +
                                "deleted_child_count INTEGER, " +
                                "container_update_id INTEGER)");
            this.database.exec ("INSERT INTO object SELECT parent, " +
                                "upnp_id, type_fk, title, timestamp, " +
                                "uri, object_update_id, " +
                                "deleted_child_count, container_update_id " +
                                "FROM object_backup");
            this.database.exec ("DROP TABLE object_backup");
            this.database.exec ("ALTER TABLE object " +
                                "ADD COLUMN is_guarded INTEGER");
            /* This intentionally sets all rows in is_guarded column
             * to zero.
             */
            this.database.exec ("UPDATE object SET is_guarded = 0");
            this.database.exec ("UPDATE schema_info SET version = '13'");
            this.database.exec (this.sql.make (SQLString.TRIGGER_COMMON));
            this.database.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            this.database.exec (this.sql.make (SQLString.INDEX_COMMON));

            this.database.commit ();
            this.database.exec ("VACUUM");
            this.database.analyze ();
        } catch (DatabaseError error) {
            this.database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            this.database = null;
        }
    }

    private void update_v13_v14 () {
        try {
            this.database.begin ();

            this.database.exec ("ALTER TABLE Object ADD COLUMN reference_id " +
                                "DEFAULT NULL");
            this.database.exec (this.sql.make (SQLString.TRIGGER_REFERENCE));

            this.database.exec ("UPDATE schema_info SET version = '14'");
            this.database.commit ();
            this.database.exec ("VACUUM");
            this.database.analyze ();
        } catch (DatabaseError error) {
            this.database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            this.database = null;
        }
    }

    private void update_v14_v15 () {
        try {
            this.database.begin ();
            this.database.exec ("ALTER TABLE Meta_Data " +
                                "   ADD COLUMN creator TEXT");
            this.database.exec ("UPDATE schema_info SET version = '15'");
            database.commit ();
            database.exec ("VACUUM");
            database.analyze ();
        } catch (DatabaseError error) {
            database.rollback ();
            warning ("Database upgrade failed: %s", error.message);
            database = null;
        }
    }

    private void update_v15_v16 () {
        try {
            this.database.begin ();
            this.database.exec ("INSERT INTO meta_data (size, mime_type, " +
                                "class, object_fk) SELECT 0, " +
                                "'inode/directory', 'object.container', " +
                                "o.upnp_id FROM object AS o WHERE " +
                                "o.type_fk=0;");
            this.database.exec ("UPDATE schema_info SET version = '16'");
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
