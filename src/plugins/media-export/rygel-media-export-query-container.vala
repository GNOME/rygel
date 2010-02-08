/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
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
using GUPnP;

internal class Rygel.MediaExportQueryContainer : Rygel.MediaDBContainer {
    private bool item_container;
    private string column;
    private string filter;
    private SearchExpression expression;

    public MediaExportQueryContainer (MediaDB media_db, string id, string name) {
        // parse the id
        // Following the schema:
        // upnp:<class> -> get all of that class (eg. Albums)
        // upnp:<class>,<item> -> get all that is contained in that class
        // If an item suffix is present, the children are items, otherwise
        // containers
        // example: upnp:album -> All albums
        //          upnp:album,The White Album -> All tracks of the White Album
        //          upnp:author,The Beatles,upnp:album -> All Albums by the Beatles
        //          the parts not prefixed by upnp: are URL-escaped
        base (media_db, id, name);
        var args = id.split(",");
        if (args.length % 2 == 0) {
            // we will contain items
            this.item_container = true;
            // TODO prepare search expression
            var exp = new RelationalExpression ();
            if (args[0] == "upnp:author")
                exp.operand1 = "dc:creator";
            else
                exp.operand1 = args[0];
            exp.op = SearchCriteriaOp.EQ;
            exp.operand2 = args[1];
            this.expression = exp;
        } else {
            this.filter = "";
            this.item_container = false;
            this.column = args[0].replace("upnp:", "");
        }
    }

    public override async Gee.List<MediaObject>? search (
                                        SearchExpression expression,
                                        uint             offset,
                                        uint             max_count,
                                        out uint         total_matches,
                                        Cancellable?     cancellable)
                                        throws GLib.Error {
        var exp = new LogicalExpression ();
        exp.operand1 = this.expression;
        exp.op = LogicalOperator.AND;
        exp.operand2 = expression;
        Gee.List<MediaObject> list;
        var old_id = this.id;
        this.id = "0";
        list = yield base.search (exp, offset, max_count, out total_matches, cancellable);
        this.id = old_id;
        return list;
    }

    public override async Gee.List<MediaObject>? get_children (
                                       uint             offset,
                                       uint             max_count,
                                       Cancellable?     cancellable)
                                       throws GLib.Error {
        if (item_container) {
            uint foobar;
            return yield this.search (this.expression,
                                      offset,
                                      max_count,
                                      out foobar,
                                      cancellable);
        }

        var children = new ArrayList<MediaObject> ();
        try {
        var data = this.media_db.get_meta_data_column_by_filter (
                                       this.column,
                                       this.filter,
                                       new ValueArray (0),
                                       offset,
                                       max_count);
       foreach (string foo in data) {
            debug ("Got child: %s", foo);
            if (foo == null)
                continue;
            var new_id = this.id + "," + foo;
            var container = new MediaExportQueryContainer (this.media_db,
                                                           new_id,
                                                           foo);
            container.parent = this;
            container.parent_ref = this;
            children.add (container);
        }
        } catch (GLib.Error err) {
            warning ("Failed to query meta data: %s", err.message);
            throw err;
        }

        return children;
    }
}
