/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

using Rygel;
using Sqlite;

public class Rygel.LMS.ImageYears : Rygel.LMS.CategoryContainer {
    private const string SQL_ALL =
        "SELECT DISTINCT(strftime('%Y', images.date, 'unixepoch')) as year " +
        "FROM images " +
        "LIMIT ? OFFSET ?;";

    private const string SQL_COUNT =
        "SELECT COUNT(DISTINCT(strftime('%Y', images.date, 'unixepoch'))) " +
        "FROM images;";

    /* actually returns multiple times the same result (because no DISTINCT) */
    /* Casting the year is a workaround so we can keep using
     * Database.find_object() without making the argument a variant or
     * something like it */
    private const string SQL_FIND_OBJECT =
        "SELECT strftime('%Y', images.date, 'unixepoch') as year " +
        "FROM images " +
        "WHERE year = CAST(? AS TEXT)";

    protected override MediaObject? object_from_statement
                                        (Statement statement) {
        return new LMS.ImageYear (this, statement.column_text (0), this.lms_db);
    }

    public ImageYears (MediaContainer parent, LMS.Database lms_db) {
        base ("years",
              parent,
              _("Years"),
              lms_db,
              ImageYears.SQL_ALL,
              ImageYears.SQL_FIND_OBJECT,
              ImageYears.SQL_COUNT,
              null,
              null);
    }
}
