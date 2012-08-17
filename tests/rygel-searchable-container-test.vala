/*
 * Copyright (C) 2012 Jens Georg.
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
    public uint child_count = 10;
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
}

public class TestContainer : MediaContainer, Rygel.SearchableContainer {
    public MainLoop loop;
    public Gee.ArrayList<string> search_classes { get; set; default = new
        Gee.ArrayList<string> ();}

    public async void test_search_no_limit () {
        uint total_matches;

        // check corners
        var result = yield search (null, 0, 0, out total_matches, "", null);
        assert (total_matches == 10);
        assert (result.size == 10);

        result = yield search (null, 10, 0, out total_matches, "",  null);
        assert (total_matches == 10);
        assert (result.size == 0);

        for (int i = 1; i < 10; ++i) {
            result = yield search (null, i, 0, out total_matches, "", null);
            assert (total_matches == 10);
            assert (result.size == 10 - i);
        }

        this.loop.quit ();
    }

    public async void test_search_with_limit () {
        uint total_matches;

        // check corners
        var result = yield search (null, 0, 4, out total_matches, "", null);
        assert (total_matches == 0);
        assert (result.size == 4);

        result = yield search (null, 10, 4, out total_matches, "", null);
        assert (total_matches == 0);
        assert (result.size == 0);

        for (int i = 1; i < 10; ++i) {
            result = yield search (null, i, 3, out total_matches, "", null);
            assert (total_matches == 0);
            assert (result.size == int.min (10 - i, 3));
        }

        this.loop.quit ();
    }


    public async MediaObjects? search (SearchExpression? expression,
                                       uint              offset,
                                       uint              max_count,
                                       out uint          total_matches,
                                       string            sort_criteria,
                                       Cancellable?      cancellable)
                                       throws Error {
        return yield this.simple_search (expression,
                                         offset,
                                         max_count,
                                         out total_matches,
                                         sort_criteria ?? this.sort_criteria,
                                         cancellable);
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
    var loop = new MainLoop ();
    var c = new TestContainer ();
    c.loop = new MainLoop ();
    c.test_search_no_limit.begin ();
    c.loop.run ();
    c.test_search_with_limit.begin ();
    c.loop.run ();

    return 0;
}
