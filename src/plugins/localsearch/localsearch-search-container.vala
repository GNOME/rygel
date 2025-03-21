/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
 *         Jens Georg <jensg@openismus.com>
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

using GUPnP;
using Gee;
using Tsparql;

/**
 * A container listing a LocalSearch search result.
 */
public class Rygel.LocalSearch.SearchContainer : SimpleContainer {
    /* class-wide constants */
    private const string MODIFIED_PROPERTY = "nfo:fileLastModified";

    public SelectionQuery query;
    public ItemFactory item_factory;

    static construct {
        update_id_hash = new HashMap<string, uint> ();
    }

    private static HashMap<string, uint> update_id_hash;

    public SearchContainer (string             id,
                            MediaContainer     parent,
                            string             title,
                            ItemFactory        item_factory,
                            QueryTriplets?     triplets = null,
                            ArrayList<string>? filters = null) {
        base (id, parent, title);

        if (update_id_hash.has_key (this.id)) {
            this.update_id = update_id_hash[this.id];
        }

        this.container_updated.connect ( (container, origin) => {
            if (origin == this) {
                update_id_hash[this.id] = this.update_id;
            }
        });

        this.item_factory = item_factory;

        var variables = new ArrayList<string> ();
        variables.add (SelectionQuery.ITEM_VARIABLE);

        QueryTriplets our_triplets;
        if (triplets != null) {
            our_triplets = triplets;
        } else {
            our_triplets = new QueryTriplets ();
        }

        our_triplets.add (new QueryTriplet
                                (SelectionQuery.ITEM_VARIABLE,
                                 "a",
                                 item_factory.category));
        our_triplets.add (new QueryTriplet
                                (SelectionQuery.ITEM_VARIABLE,
                                 "nie:isStoredAs",
                                SelectionQuery.STORAGE_VARIABLE));

        var property_map = UPnPPropertyMap.get_property_map ();
        foreach (var property in this.item_factory.properties) {
            variables.add (property_map[property]);
        }

        var order_by = MODIFIED_PROPERTY +
                       "(" +
                       SelectionQuery.STORAGE_VARIABLE +
                       ")";

        this.query = new SelectionQuery (variables,
                                         our_triplets,
                                         filters,
                                         this.item_factory.graph,
                                         order_by);

        this.get_children_count.begin ();
    }

    public override async MediaObjects? get_children (uint       offset,
                                                      uint       max_count,
                                                      string     sort_criteria,
                                                      Cancellable? cancellable)
                                                      throws GLib.Error {
        var expression = new RelationalExpression ();
        expression.op = SearchCriteriaOp.EQ;
        expression.operand1 = "@parentID";
        expression.operand2 = this.id;

        uint total_matches;

        return yield this.execute_query (expression,
                                         sort_criteria,
                                         offset,
                                         max_count,
                                         cancellable,
                                         out total_matches);
    }

    public async MediaObjects? execute_query (SearchExpression? expression,
                                              string            sort_criteria,
                                              uint              offset,
                                              uint              max_count,
                                              Cancellable?      cancellable,
                                              out uint          total_matches)
                                              throws GLib.Error {
        var results = new MediaObjects ();

        var query = this.create_query (expression as RelationalExpression,
                                       (int) offset,
                                       (int) max_count,
                                       sort_criteria);

        if (query != null) {
            yield query.execute (RootContainer.connection);

            /* Iterate through all items */
            while (yield query.result.next_async ()) {
                var id = query.result.get_string (0);
                id = this.create_child_id_for_urn (id);
                var uri = query.result.get_string (1);

                var item = this.item_factory.create (id,
                                                     uri,
                                                     this,
                                                     query.result);
                results.add (item);
            }

            query.result.close ();
        }

        total_matches = results.size;

        return results;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws GLib.Error {
        if (!this.is_our_child (id)) {
            return null;
        }

        var expression = new RelationalExpression ();
        expression.op = SearchCriteriaOp.EQ;
        expression.operand1 = "@id";
        expression.operand2 = id;

        uint total_matches;
        var results = yield this.execute_query (expression,
                                                "",
                                                0,
                                                1,
                                                cancellable,
                                                out total_matches);
        if (results.size > 0) {
            return results[0];
        } else {
            return null;
        }
    }

    public string create_child_id_for_urn (string urn) {
        return this.id + "," + urn;
    }

    // Returns the URN and the ID of the parent this item belongs to, or null
    // if item_id is invalid
    protected string? get_item_info (string     item_id,
                                     out string parent_id) {
        var tokens = item_id.split (",", 2);

        if (tokens[0] != null && tokens[1] != null) {
            parent_id = tokens[0];

            return tokens[1];
        } else {
            parent_id = null;

            return null;
        }
    }

    internal async void get_children_count () {
        try {
            var query = new SelectionQuery.clone (this.query);

            query.variables = new ArrayList<string> ();
            query.variables.add ("COUNT(" +
                                 SelectionQuery.ITEM_VARIABLE +
                                 ") AS ?x");

            yield query.execute (RootContainer.connection);

            if (query.result.next ()) {
                this.child_count = int.parse (query.result.get_string (0));
                this.updated ();
            }

            query.result.close ();
        } catch (GLib.Error error) {
            critical (_("Error getting item count under category “%s”: %s"),
                      this.item_factory.category,
                      error.message);

            return;
        }
    }

    private bool is_our_child (string id) {
        return id.has_prefix (this.id + ",");
    }

    private SelectionQuery? create_query (RelationalExpression? expression,
                                          int offset,
                                          int max_count,
                                          string sort_criteria = "") {
        if (expression.operand1 == "upnp:class" &&
            !this.item_factory.upnp_class.has_prefix (expression.operand2)) {
            return null;
        }

        SelectionQuery query;
        if (sort_criteria == null || sort_criteria == "") {
            query = new SelectionQuery.clone (this.query);
        } else {
            query = create_sorted_query (sort_criteria);
        }

        if (expression.operand1 == "@parentID") {
            if (!expression.compare_string (this.id)) {
                return null;
            }
        } else if (expression.operand1 != "upnp:class") {
            var filter = create_filter_for_child (expression);
            if (filter != null) {
                query.filters.insert (0, filter);
            } else {
                return null;
            }
        }

        query.offset = offset;
        query.max_count = max_count;

        return query;
    }

    private SelectionQuery? create_sorted_query (string sort_criteria) {
         var key_chain_map = UPnPPropertyMap.get_property_map ();
         var sort_props = sort_criteria.split (",");
         string order = "";
         ArrayList<string> variables = new ArrayList<string> ();
         ArrayList<string> filters = new ArrayList<string> ();

         variables.add_all (this.query.variables);
         filters.add_all (this.query.filters);

         foreach (string s in sort_props) {
             var key = key_chain_map[s.substring(1)];
             if (key.index_of (SelectionQuery.ITEM_VARIABLE) == 0 ||
                 key.index_of (SelectionQuery.STORAGE_VARIABLE) == 0) {
                 continue;
             }


             if (s.has_prefix("-")) {
                 order += "DESC (" +
                           key + ") ";
             } else {
                 order += key + " ";
             }
         }

         if (order == "") {
             order = this.query.order_by;
         }

         return new SelectionQuery (
                                variables,
                                new QueryTriplets.clone(this.query.triplets),
                                filters,
                                this.item_factory.graph,
                                order);
    }

    private string? urn_to_utf8 (string urn) {
        var urn_builder = new StringBuilder ();
        unowned string s = urn;

        for (; s.get_char () != 0; s = s.next_char ()) {
            unichar character = s.get_char ();
            if (!(character.iscntrl () || !character.validate ())) {
                urn_builder.append_unichar (character);
            }
        }

        return urn_builder.str;
    }

    private string? create_filter_for_child (RelationalExpression expression) {
        string filter = null;
        string variable = null;
        string value = null;

        if (expression.operand1 == "@id") {
            variable = SelectionQuery.ITEM_VARIABLE;

            string parent_id;

            var urn = this.get_item_info (expression.operand2, out parent_id);

            if (!urn.validate ()) {
                urn = urn_to_utf8 (urn);
            }

            if (urn == null || parent_id == null || parent_id != this.id) {
                return null;
            }

            urn = Query.escape_string (urn);

            switch (expression.op) {
                case SearchCriteriaOp.EQ:
                    value = "<" + urn + ">";
                    break;
                case SearchCriteriaOp.CONTAINS:
                    value = expression.operand2;
                    break;
                default:
                    break;
            }
        }

        if (variable == null || value == null) {
            return null;
        }

        switch (expression.op) {
            case SearchCriteriaOp.EQ:
                filter = variable + " = " + value;
                break;
            case SearchCriteriaOp.CONTAINS:
                // We need to escape this twice for LocalSearch
                var regex = Query.escape_regex (value);

                filter = "regex(" + variable + ", \"" + regex + "\", \"i\")";
                break;
            default:
                break;
        }

        return filter;
    }
}
