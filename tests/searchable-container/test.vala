/*
 * Copyright (C) 2012 Jens Georg.
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

public class RelationalExpression : SearchExpression {
}

namespace SearchCriteriaOp {
    public const string EQ = "=";
}

public class SearchExpression : Object {
    public string operand1;
    public string operand2;
    public string op;

    public bool satisfied_by (MediaObject object) {
        return true;
    }
}

public class MediaObject : Object {
}

public class MediaContainer : MediaObject {
    public string sort_criteria = "+dc:title";
    public int child_count = 10;
    public bool create_mode_enabled = false;
    public int all_child_count {
        get { return this.child_count; }
    }
    public async MediaObjects? get_children (
                                            uint offset,
                                            uint max_count,
                                            string sort_criteria,
                                            Cancellable? cancellable)
                                            throws Error {
        Idle.add ( () => { get_children.callback (); return false; });
        yield;

        var result = new MediaObjects ();
        for (int i = 0; i < 10; ++i) {
            result.add (new MediaObject ());
        }

        return result;
    }

    internal void check_search_expression (SearchExpression? expression) {}
}

public class TestContainer : MediaContainer, Rygel.SearchableContainer {
    public MainLoop loop;
    public Gee.ArrayList<string> search_classes { get; set; default = new
        Gee.ArrayList<string> ();}

    public async void test_search_no_limit () {
        uint total_matches = 0;

        // check corners
        try {
            var result = yield search (null, 0, 0, "", null, out total_matches);
            assert (total_matches == 10);
            assert (result.size == 10);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        try {
            var result = yield search (null, 10, 0, "",  null, out total_matches);
            assert (total_matches == 10);
            assert (result.size == 0);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        for (int i = 1; i < 10; ++i) {
            try {
                var result = yield search (null, i, 0, "", null, out total_matches);
                assert (total_matches == 10);
                assert (result.size == 10 - i);
            } catch (GLib.Error error) {
                assert_not_reached ();
            }
        }

        this.loop.quit ();
    }

    public async void test_search_with_limit () {
        uint total_matches;

        // check corners
        try {
            var result = yield search (null, 0, 4, "", null, out total_matches);
            assert (total_matches == 0);
            assert (result.size == 4);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        try
        {
            var result = yield search (null, 10, 4, "", null, out total_matches);
            assert (total_matches == 0);
            assert (result.size == 0);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        for (int i = 1; i < 10; ++i) {
            try {
                var result = yield search (null, i, 3, "", null, out total_matches);
                assert (total_matches == 0);
                assert (result.size == int.min (10 - i, 3));
            } catch (GLib.Error error) {
                assert_not_reached ();
            }
        }

        this.loop.quit ();
    }

    /* TODO: This is just here to avoid a warning about
     * serialize_search_parameters() not being used.
     * How should this really be tested?
     */
    public void test_serialization() {
         var writer = new GUPnP.DIDLLiteWriter(null);
         var didl_container = writer.add_container();
         serialize_search_parameters(didl_container);
    }

    public async MediaObjects? search (SearchExpression? expression,
                                       uint              offset,
                                       uint              max_count,
                                       string            sort_criteria,
                                       Cancellable?      cancellable,
                                       out uint          total_matches)
                                       throws Error {
        return yield this.simple_search (expression,
                                         offset,
                                         max_count,
                                         sort_criteria ?? this.sort_criteria,
                                         cancellable,
                                         out total_matches);
    }

}

public class MediaObjects : Gee.ArrayList<MediaObject> {
    public override Gee.List<MediaObject>? slice (int start, int stop) {
        var slice = base.slice (start, stop);
        var ret = new MediaObjects ();

        ret.add_all (slice);

        return ret;
    }
}

int main ()
{
    var c = new TestContainer ();
    c.loop = new MainLoop ();
    c.test_search_no_limit.begin ();
    c.loop.run ();
    c.test_search_with_limit.begin ();
    c.loop.run ();

    return 0;
}
