/*
 * Copyright (C) 2011 Jens Georg <mail@jensge.org>.
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

internal class Rygel.MediaExport.QueryContainerFactory : Object {
    // private static members
    private static QueryContainerFactory instance;

    // private members
    private HashMap<string,string> virtual_container_map;

    // public static functions
    public static QueryContainerFactory get_default () {
        if (unlikely (instance == null)) {
            instance = new QueryContainerFactory ();
        }

        return instance;
    }

    // constructors
    private QueryContainerFactory () {
        this.virtual_container_map = new HashMap<string, string> ();
    }

    // public functions

    /**
     * Register a plaintext description for a query container. The passed
     * string will be modified to the checksum id of the container.
     *
     * @param id Originally contains the plaintext id which is replaced with
     *           the hashed id on return.
     */
    public void register_id (ref string id) {
        var md5 = Checksum.compute_for_string (ChecksumType.MD5, id);

        if (!this.virtual_container_map.has_key (md5)) {
            this.virtual_container_map[md5] = id;
            debug ("Registering %s for %s", md5, id);
        }

        id = QueryContainer.PREFIX + md5;
    }

    /**
     * Get the plaintext definition from a hashed id.
     *
     * Inverse function of register_id().
     *
     * @param hash A hashed id
     * @return the plaintext defintion of the virtual folder
     */
    public string? get_virtual_container_definition (string hash) {
        var id = hash.replace (QueryContainer.PREFIX, "");

        return this.virtual_container_map[id];
    }

    /**
     * Factory method.
     *
     * Create a QueryContainer directly from MD5 hashed id.
     *
     * @param cache An instance of the meta-data cache
     * @param id    The hashed id of the container
     * @param name  An the title of the container. If not supplied, it will
     *              be derived from the plain-text description of the
     *              container
     * @return A new instance of QueryContainer
     */
    public QueryContainer create_from_id (MediaCache cache,
                                          string     id,
                                          string     name = "") {
        var definition = this.get_virtual_container_definition (id);

        return this.create_from_description (cache, definition, name);
    }

    /**
     * Factory method.
     *
     * Create a QueryContainer from a plain-text description string.
     *
     * @param cache      An instance of the meta-data cache
     * @param definition Plain-text defintion of the query-container
     * @param name       The title of the container. If not supplied, it
     *                   will be derived from the plain-text description of
     *                   the container
     * @return A new instance of QueryContainer
     */
    public QueryContainer create_from_description (MediaCache cache,
                                                   string     definition,
                                                   string     name = "") {
        var title = name;
        string attribute = null;
        string pattern = null;
        var id = definition;

        this.register_id (ref id);

        var expression = this.parse_description (definition,
                                                 out pattern,
                                                 out attribute,
                                                 ref title);

        if (pattern == null || pattern == "") {
            return new LeafQueryContainer (cache, expression, id, title);
        } else {
            return new NodeQueryContainer (cache,
                                           expression,
                                           id,
                                           title,
                                           pattern,
                                           attribute);
        }
    }

    // private methods

    /**
     * Parse a plaintext container description into a search expression.
     *
     * Also generates a name for the container and other meta-data necessary
     * for node containers.
     *
     * @param description The plaintext container description
     * @param pattern     Contains the pattern used for child containers if
     *                    descrption is for a node container, null otherwise.
     * @param attribute   Contains the UPnP attribute the container describes
     *                    if description is for a node container, null
     *                    otherwise.
     * @param name        If passed empty, name will be generated from the
     *                    description.
     * @return A SearchExpression corresponding to the non-variable part of
     *         the description.
     */
    private SearchExpression parse_description (string     description,
                                                out string pattern,
                                                out string attribute,
                                                ref string name) {
        var args = description.split (",");
        var expression = null as SearchExpression;
        pattern = null;
        attribute = null;

        int i = 0;
        while (i < args.length) {
            if (args[i + 1] != "?") {
                this.update_search_expression (ref expression,
                                               args[i],
                                               args[i + 1]);
            } else {
                args[i + 1] = "%s";
                attribute = args[i].replace (QueryContainer.PREFIX, "");
                attribute = Uri.unescape_string (attribute);
                pattern = string.joinv (",", args);

                if (name == "" && i > 0) {
                    name = Uri.unescape_string (args[i - 1]);
                }

                break;
            }

            i += 2;
        }

        return expression;
    }

    /**
     * Update a SearchExpression with a new key = value condition.
     *
     * Will modifiy the passed expression to (expression AND (key = value))
     *
     * @param expression The expression to update or null to create a new one
     * @param key        Key of the key/value condition
     * @param value      Value of the key/value condition
     */
    private void update_search_expression (ref SearchExpression? expression,
                                           string                key,
                                           string                @value) {
        var subexpression = new RelationalExpression ();
        var clean_key = key.replace (QueryContainer.PREFIX, "");
        subexpression.operand1 = Uri.unescape_string (clean_key);
        subexpression.op = SearchCriteriaOp.EQ;
        subexpression.operand2 = Uri.unescape_string (@value);

        if (expression != null) {
            var conjunction = new LogicalExpression ();
            conjunction.operand1 = expression;
            conjunction.operand2 = subexpression;
            conjunction.op = LogicalOperator.AND;
            expression = conjunction;
        } else {
            expression = subexpression;
        }
    }
}
