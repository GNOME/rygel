/*
 * Copyright (C) 2012 Jens Georg <mail@jensge.org>
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

private class Rygel.Regression {
    private MainLoop loop;

    public static int main (string[] args) {
        var test = new Regression ();

        test.run ();

        return 0;
    }

    public void run () {
        this.loop = new MainLoop ();
        test_661482.begin ();
        loop.run ();
    }

    public async void test_661482 () {
        var container = new SimpleContainer ("0", null, "0");
        var item_1 = new ImageItem ("Z", container, "Z");
        var item_2 = new ImageItem ("M", container, "M");
        var item_3 = new ImageItem ("A", container, "A");

        container.add_child_item (item_1);
        container.add_child_item (item_2);
        container.add_child_item (item_3);

        try {
            var list = yield container.get_children (0, 3, "+dc:title", null);
            for (var i = 0; i < 3; ++i) {
                var children = yield container.get_children (i,
                                                             1,
                                                             "+dc:title",
                                                             null);
                assert (children[0].title == list[i].title);
            }

        } catch (Error error) { assert_not_reached (); }

        loop.quit ();
    }
}
