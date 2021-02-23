/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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
using Gee;

internal class Rygel.MediaExport.MediaCacheUpgrader {
    private unowned Database.Database database;
    private unowned SQLFactory sql;

    private const string UPDATE_V3_V4_STRING_2 =
    "UPDATE meta_data SET object_fk = " +
        "(SELECT upnp_id FROM Object WHERE metadata_fk = meta_data.id)";

    private const string UPDATE_V3_V4_STRING_3 =
    "ALTER TABLE Object ADD timestamp INTEGER";

    private const string UPDATE_V3_V4_STRING_4 =
    "UPDATE Object SET timestamp = 0";

    public MediaCacheUpgrader (Database.Database database, SQLFactory sql) {
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
                warning (_("Failed to force reindex to fix database: %s"),
                         error.message);
            }
        }
    }

    public void ensure_indices () {
        try {
            this.database.exec (this.sql.make (SQLString.INDEX_COMMON));
            this.database.analyze ();
        } catch (Error error) {
            warning (_("Failed to create indices: %s"),
                     error.message);
        }
    }

    public void upgrade (int old_version) throws MediaCacheError {
        debug ("Older schema detected. Upgrading...");
        int current_version = int.parse (SQLFactory.SCHEMA_VERSION);
        while (old_version < current_version) {
            switch (old_version) {
                case 16:
                    this.update_v17_v18 (false);
                    // We skip 17 here since 17 -> 18 is just a table rename
                    old_version++;
                    break;
                case 17:
                    this.update_v17_v18 (true);
                    break;
                default:
                    throw new MediaCacheError.UPGRADE_FAILED (_("Cannot upgrade from version %d"), old_version);
            }
            old_version++;
        }
    }

    private void update_v17_v18 (bool move_data) throws MediaCacheError {
        try {
            this.database.begin ();
            this.database.exec (this.sql.make (SQLString.CREATE_IGNORELIST_TABLE));
            this.database.exec (this.sql.make (SQLString.CREATE_IGNORELIST_INDEX));
            if (move_data) {
                database.exec ("INSERT INTO ignorelist SELECT * FROM blacklist");
            }
            database.exec ("UPDATE schema_info SET VERSION = '18'");
            this.database.commit ();
            this.database.exec ("VACUUM");
            this.database.analyze ();
        } catch (Database.DatabaseError error) {
            database.rollback ();
            throw new MediaCacheError.UPGRADE_FAILED (_("Database upgrade to v18 failed: %s"), error.message);
        }
    }
}
