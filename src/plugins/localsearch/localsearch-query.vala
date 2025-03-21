/*
 * Copyright (C) 2008-2012 Nokia Corporation.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Ivan Frade <ivan.frade@nokia.com>
 *          Jens Georg <jensg@openismus.com>
 *          Luis de Bethencourt <luisbg@collabora.com>
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
using Tsparql;

/**
 * Represents LocalSearch SPARQL query
 */
public abstract class Rygel.LocalSearch.Query {
    public QueryTriplets triplets;

    protected Query (QueryTriplets triplets) {
        this.triplets = triplets;
    }

    public abstract async void execute (SparqlConnection resources)
                                        throws Error,
                                               IOError,
                                               SparqlError,
                                               DBusError;

    // Deriving classes should override this method and complete it by
    // adding the first part of the query
    public virtual string to_string () {
        return this.triplets.serialize ();
    }

    /**
     * Convenience function to combine Query.escape_string and
     * Regex.escape_string in one function call
     *
     * @param literal A string to escape
     *
     * @return A newly allocated string with the sparql-escaped regex-escaped
     * version of literal. The returned string should be freed with g_free()
     * when no longer needed.
     */
    public static string escape_regex (string literal) {
        return escape_string (Regex.escape_string (literal));
    }

    /**
     * tracker_sparql_escape_string: Escapes a string so that it can be
     * used in a SPARQL query. Copied from LocalSearch project.
     *
     * @param literal A string to escape
     *
     * @return A newly-allocated string with the escaped version of
     * literal. The returned string should be freed with g_free() when no
     * longer needed.
     */
    public static string escape_string (string literal) {
        StringBuilder str = new StringBuilder ();
        char *p = literal;

        while (*p != '\0') {
            size_t len = Posix.strcspn ((string) p, "\t\n\r\b\f\"\\");
            str.append_len ((string) p, (long) len);
            p += len;

            switch (*p) {
                case '\t':
                    str.append ("\\t");
                    break;
                case '\n':
                    str.append ("\\n");
                    break;
                case '\r':
                    str.append ("\\r");
                    break;
                case '\b':
                    str.append ("\\b");
                    break;
                case '\f':
                    str.append ("\\f");
                    break;
                case '"':
                    str.append ("\\\"");
                    break;
                case '\\':
                    str.append ("\\\\");
                    break;
                default:
                    continue;
            }

            p++;
        }

        return str.str;
    }
}
