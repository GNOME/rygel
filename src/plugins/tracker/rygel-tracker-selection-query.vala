/*
 * Copyright (C) 2010-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Gee;
using Tracker;

/**
 * Represents Tracker SPARQL Selection query
 */
public class Rygel.Tracker.SelectionQuery : Query {
    public const string ITEM_VARIABLE = "?item";
    private const string SHARED_FILTER = "(!BOUND(nmm:uPnPShared(" +
                                         ITEM_VARIABLE + ")) ||" +
                                         " nmm:uPnPShared(" +
                                         ITEM_VARIABLE +
                                         ") = true) && " +
                                         "(BOUND(nie:url(" +
                                         ITEM_VARIABLE + ")))";
    private const string STRICT_SHARED_FILTER = "(BOUND(nmm:dlnaProfile(" +
                                                ITEM_VARIABLE + ")))";
    private const string AVAILABLE_FILTER = "(tracker:available(" +
                                            ITEM_VARIABLE + ") = true)";

    private string uri_filter;

    public ArrayList<string> variables;
    public ArrayList<string> filters;

    public string order_by;
    public int offset;
    public int max_count;

    public Sparql.Cursor result;

    public SelectionQuery (ArrayList<string>  variables,
                           QueryTriplets      triplets,
                           ArrayList<string>? filters,
                           string?            order_by = null,
                           int                offset = 0,
                           int                max_count = -1) {
        base (triplets);

        if (filters != null) {
            this.filters = filters;
        } else {
            this.filters = new ArrayList<string> ();
        }

        this.variables = variables;
        this.order_by = order_by;
        this.offset = offset;
        this.max_count = max_count;

        ArrayList<string> uris;
        string[] uri_filters = new string[0];

        var config = MetaConfig.get_default ();

        try {
            uris = config.get_string_list ("Tracker", "only-export-from");
        } catch (Error error) {
            uris = new ArrayList<string> ();
        }

        var home_dir = File.new_for_path (Environment.get_home_dir ());
        unowned string pictures_dir = Environment.get_user_special_dir
                                        (UserDirectory.PICTURES);
        unowned string videos_dir = Environment.get_user_special_dir
                                        (UserDirectory.VIDEOS);
        unowned string music_dir = Environment.get_user_special_dir
                                        (UserDirectory.MUSIC);

        foreach (var uri in uris) {
            var file = File.new_for_commandline_arg (uri);
            if (!file.equal (home_dir)) {
                var actual_uri = uri;

                if (pictures_dir != null) {
                    actual_uri = actual_uri.replace ("@PICTURES@", pictures_dir);
                }
                if (videos_dir != null) {
                    actual_uri = actual_uri.replace ("@VIDEOS@", videos_dir);
                }
                if (music_dir != null) {
                    actual_uri = actual_uri.replace ("@MUSIC@", music_dir);
                }

                if (actual_uri.contains ("@PICTURES@") ||
                    actual_uri.contains ("@VIDEOS@") ||
                    actual_uri.contains ("@MUSIC@")) {
                    continue;
                }

                // protect against special directories expanding to $HOME
                file = File.new_for_commandline_arg (actual_uri);
                if (file.equal (home_dir)) {
                    continue;
                }

                uri_filters += "tracker:uri-is-descendant(\"%s\", nie:url(%s))".printf
                                (file.get_uri (), ITEM_VARIABLE);
            }
        }

        if (uri_filters.length != 0) {
            this.uri_filter = "(%s)".printf (string.joinv ("||", uri_filters));
        } else {
            this.uri_filter = null;
        }
    }

    public SelectionQuery.clone (SelectionQuery query) {
        this (copy_str_list (query.variables),
              new QueryTriplets.clone (query.triplets),
              copy_str_list (query.filters),
              query.order_by,
              query.offset,
              query.max_count);
    }

    public override async void execute (Sparql.Connection resources)
                                        throws Error,
                                               IOError,
                                               Sparql.Error,
                                               DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        result = yield resources.query_async (str);
    }

    public override string to_string () {
        var query = "SELECT ";

        foreach (var variable in this.variables) {
            query += " " + variable;
        }

        query += " WHERE { " + base.to_string ();

        var filters = new ArrayList<string> ();
        filters.add_all (this.filters);
        // Make sure we don't expose items that are marked not to be shared
        filters.add (SHARED_FILTER);

        // Make sure we don't expose items on removable media that isn't
        // mounted
        filters.add (AVAILABLE_FILTER);

        // If strict sharing is enabled, only expose files that have a DLNA
        // profile set
        try {
            var config = MetaConfig.get_default ();
            if (config.get_bool ("Tracker", "strict-sharing")) {
                filters.add (STRICT_SHARED_FILTER);
            }
        } catch (Error error) {};

        // Limit the files to a set of folders that may have been configured
        if (uri_filter != null) {
            filters.add (uri_filter);
        }

        if (filters.size > 0) {
            query += " FILTER (";
            for (var i = 0; i < filters.size; i++) {
                query += filters[i];

                if (i < filters.size - 1) {
                    query += " && ";
                }
            }
            query += ")";
        }

        query += " }";

        if (this.order_by != null) {
            query += " ORDER BY " + order_by;
        }

        if (this.offset > 0) {
            query += " OFFSET " + this.offset.to_string ();
        }

        if (this.max_count > 0) {
            query += " LIMIT " + this.max_count.to_string ();
        }

        return query;
    }

    private static ArrayList<string> copy_str_list (Gee.List<string> str_list) {
        var copy = new ArrayList<string> ();

        copy.add_all (str_list);

        return copy;
    }
}
