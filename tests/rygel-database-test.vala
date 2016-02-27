/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * Test that database errors are reported correctly. This is a side-bug
 * discovered during fixing this bug.
 */
public void test_bgo683926_1 () {
    Rygel.Database.Database db = null;

    try {
        db = new Rygel.Database.Database (":memory:");
        db.exec ("create table object (id text not null, title text not null);");
        db.exec ("insert into object (id, title) VALUES ('a', 'b');");
    } catch (Error e) {
        error ("=> Database preparation failed: %s", e.message);
    }

    try {
        Value[] val = { "c" };
        db.exec ("replace into object (title) VALUES (?);", val);
        assert_not_reached ();
    } catch (Error e) {
        // Receiving an error here is expected
    }
}

int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/librygel-db/regression/bgo689326_1",
                   test_bgo683926_1);

    return Test.run ();
}
