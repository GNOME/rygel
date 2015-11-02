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
    Rygel.MediaExport.Database db = null;

    try {
        db = new Rygel.MediaExport.Database (":memory:");
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

public void test_bgo683926_2 () {
    try {
        Rygel.MediaExport.MediaCache.ensure_exists ();
        var cache = Rygel.MediaExport.MediaCache.get_default ();
        var container = new Rygel.SimpleContainer.root ("foo");
        container.id = "foo";
        cache.save_container (container);

        var item = new Rygel.MusicItem ("1",
                                        container,
                                        "Static Title");
        item.mime_type = "audio/mpeg";
        cache.save_item (item, true);
        item.title = "Changed title";
        cache.save_item (item);
        item = cache.get_object ("1") as Rygel.MusicItem;
        assert (item.title == "Static Title");
    } catch (Error error) {
        assert_not_reached ();
    }
}


/**
 * Dummy function to silence the vala warnings
 */
void test_silence_vala () {
    try {
        Rygel.MediaExport.Database.null ();
        var db = new Rygel.MediaExport.Database (":memory:");
        db.analyze ();
        db.begin ();
        db.commit ();
        db.rollback ();
        db.query_value ("SELECT 1;");
        foreach (var c in db.exec_cursor ("SELECT 1;")) {
            c.data_count ();
        }
    } catch (Error error) { }
}

class TestConfig : Rygel.BaseConfiguration {
    public override bool get_bool (string section, string key) throws Error {
        if (section == "MediaExport" && key == "use-temp-db") {
            return true;
        }

        throw new Rygel.ConfigurationError.NO_VALUE_SET ("No value available");
    }
}

int main (string[] args) {
    Test.init (ref args);

    if (false != false) {
        test_silence_vala ();
    }

    Rygel.MetaConfig.register_configuration (new TestConfig ());

    Test.add_func ("/plugins/media-export/regression/bgo689326_1",
                   test_bgo683926_1);
/*    Test.add_func ("/plugins/media-export/regression/bgo689326_2",
                   test_bgo683926_2); */
    return Test.run ();
}
