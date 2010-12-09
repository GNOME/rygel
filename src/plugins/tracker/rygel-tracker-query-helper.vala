/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008,2010 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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

using GUPnP;
using Gee;

/**
 * Builds a SPARQL query using Query classes and organises the results
 */
public class Rygel.Tracker.QueryHelper : Object {
    public unowned SearchContainer container;

    public QueryHelper (SearchContainer container) {
        this.container = container;
    }

    public SearchQuery create_query (SearchExpression? expression = null,
                                     string?           order_by = null,
                                     uint              offset = 0,
                                     uint              max_count = 0,
                                     Cancellable?      cancellable) {
        // Collect key chains
        var key_chains = new ArrayList<ArrayList<string>> ();
        var key_chain_map = KeyChainMap.get_key_chain_map ();
        foreach (var property in this.container.item_factory.properties) {
            key_chains.add (key_chain_map[property]);
        }

        // Collect triplets
        var triplets = new QueryTriplets ();
        triplets.add_triplet (new QueryTriplet
                                        (SelectionQuery.ITEM_VARIABLE,
                                         "a",
                                         this.container.item_factory.category));

        // Create filters
        var filter = this.create_query_filter (expression);

        // Create query
        var query = new SearchQuery (key_chains,
                                     triplets,
                                     filter,
                                     order_by,
                                     offset,
                                     max_count,
                                     cancellable);

        return query;
    }

    public MediaObjects? get_results (SearchQuery query) throws Error {
        assert (query.result != null);

        var results = new MediaObjects ();

        for (uint i = 0; i < query.result.length[0]; i++) {
            var id = this.container.create_child_id_for_urn
                                        (query.result[i, 0]);
            var uri = query.result[i, 1];
            string[] metadata = this.slice_strvv_tail (query.result, i, 1);

            var item = this.container.item_factory.create (id,
                                                           uri,
                                                           this.container,
                                                           metadata);
            results.add (item);
        }

        return results;
    }

    /**
     * Given a UPnP search expression, convert it to a SPARQL search
     * expression. This involves converting UPnP properties into tracker
     * ontology properties. UPnP properties such as @id and @parentID have
     * to be handled here as there is no direct mapped property to use in
     * tracker query.
     *
     * @param expression The UPnP search expression
     *
     * @return Newly created SPARQL filter expression
     */
    private QueryFilter? create_query_filter (SearchExpression? expression) {
        if (expression == null) {
            return null;
        }

        if (expression is LogicalExpression) {
            return this.log_expr_to_filter (expression as LogicalExpression);
        } else if (expression is RelationalExpression) {
            return this.rel_expr_to_filter (expression as RelationalExpression);
        } else {
            assert_not_reached ();
        }
    }

    private QueryFilter log_expr_to_filter (LogicalExpression logic) {
        LogicalFilter.Operator op;

        switch (logic.op) {
        case LogicalOperator.AND:
            op = LogicalFilter.Operator.AND;

            break;
        case LogicalOperator.OR:
            op = LogicalFilter.Operator.OR;

            break;
        default:
            assert_not_reached ();
        }

        var operand1 = this.create_query_filter (logic.operand1);
        var operand2 = this.create_query_filter (logic.operand2);

        var new_logic = new LogicalFilter (op, operand1, operand2);

        return new_logic.simplify ();
    }

    private QueryFilter rel_expr_to_filter (RelationalExpression relation) {
        string operand1 = null;

        var key_chain_map = KeyChainMap.get_key_chain_map ();

        switch (relation.operand1) {
        case "@parentID":
            var result = relation.compare_string (this.container.id);

            return new BooleanFilter (result);

        case "upnp:class":
            var upnp_class = this.container.item_factory.upnp_class;
            var result = relation.compare_string (upnp_class);

            return new BooleanFilter (result);

        case "upnp:createClass":
            var result = relation.compare_string (null);

            return new BooleanFilter (result);

        case "@id":
            operand1 = "fn:concat(\"" +
                       this.container.id +
                       ",\", xsd:string(" +
                       SearchQuery.ITEM_VARIABLE +
                       "))";

            break;
        case "dc:title":
            // dc:title property set on a media item is either the tracker
            // title or the file name in its absence. So, we need to
            // search accordingly.
            var title = key_chain_map.map_property ("dc:title");
            var file_name = key_chain_map.map_property ("fileName");
            operand1 = "tracker:coalesce(" + title + ", " + file_name + ")";

            break;
        case "dc:creator":
        case "upnp:artist":
        case "upnp:album":
            operand1 = key_chain_map.map_property (relation.operand1);

            break;
        default:
            assert_not_reached ();
        }

        var value = relation.operand2;

        QueryFilter filter = null;

        switch (relation.op) {
        case SearchCriteriaOp.EXISTS:
            filter = new BoundFilter (operand1);
            if (value == "false") {
                filter = new LogicalFilter (LogicalFilter.Operator.NOT, filter);
            }

            break;
        case SearchCriteriaOp.EQ:
            var regex = Query.escape_string (Regex.escape_string (value));
            filter = new RegexFilter (operand1, "^" + regex + "$", "i");

            break;
        case SearchCriteriaOp.NEQ:
            var regex = Query.escape_string (Regex.escape_string (value));
            filter = new RegexFilter (operand1, "^" + regex + "$", "i");
            filter = new LogicalFilter (LogicalFilter.Operator.NOT, filter);

            break;
        case SearchCriteriaOp.CONTAINS:
            var regex = Query.escape_string (Regex.escape_string (value));
            filter = new RegexFilter (operand1, regex, "i");

            break;
        case SearchCriteriaOp.DOES_NOT_CONTAIN:
            var regex = Query.escape_string (Regex.escape_string (value));
            filter = new RegexFilter (operand1, regex, "i");
            filter = new LogicalFilter (LogicalFilter.Operator.NOT, filter);

            break;
        case SearchCriteriaOp.DERIVED_FROM:
            var regex = Query.escape_string (Regex.escape_string (value));
            filter = new RegexFilter (operand1, "^" + regex + "($|\\.)", "i");

            break;
        }

        return filter;
    }

    /**
     * Chops the tail of a particular row in a 2-dimensional string array.
     *
     * param strvv the 2-dimenstional string array to chop the tail of.
     * param row the row whose tail needs to be chopped off.
     * param index index of the first element in the tail.
     *
     * FIXME: Stop using it once vala supports array slicing syntax for
     *        multi-dimentional arrays.
     */
    protected string[] slice_strvv_tail (string[,] strvv,
                                         uint row,
                                         uint index) {
        var slice = new string[strvv.length[1] - index];

        for (var i = 0; i < slice.length; i++) {
            slice[i] = strvv[row, i + index];
        }

        return slice;
    }
}
