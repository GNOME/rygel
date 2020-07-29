/*
 * Copyright (C) 2011 Jens Georg <mail@jensge.org>.
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
using GUPnP;

/**
 * A helper class to create QueryContainer instances based on IDs.
 */
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
     * @param id    The hashed id of the container
     * @param name  An the title of the container. If not supplied, it will
     *              be derived from the plain-text description of the
     *              container
     * @return A new instance of QueryContainer or null if id does not exist
     */
    public QueryContainer? create_from_hashed_id (string id,
                                                  string name = "") {
        var definition_id = this.get_virtual_container_definition (id);
        if (definition_id == null) {
            return null;
        }

        return this.create_from_description_id (definition_id, name);
    }

    /**
     * Factory method.
     *
     * Create a QueryContainer from a plain-text description string.
     *
     * @param definition Plain-text defintion of the query-container
     * @param name       The title of the container. If not supplied, it
     *                   will be derived from the plain-text description of
     *                   the container
     * @return A new instance of QueryContainer
     */
    public QueryContainer create_from_description_id (string definition_id,
                                                      string name = "") {
        var title = name;
        string attribute = null;
        string pattern = null;
        string upnp_class = null;
        QueryContainer container;

        var id = definition_id;
        this.register_id (ref id);

        var expression = QueryContainerFactory.parse_description
                                        (definition_id,
                                         out pattern,
                                         out attribute,
                                         out upnp_class,
                                         ref title);

        // Create a node or leaf container,
        // depending on whether the definition specifies a pattern.
        if (pattern == null || pattern == "") {
            container =  new LeafQueryContainer (expression,
                                                 id,
                                                 title);
        } else {
            container = new NodeQueryContainer (expression,
                                                id,
                                                title,
                                                pattern,
                                                attribute);
        }

        if (upnp_class != null) {
            container.upnp_class = upnp_class;
            if (upnp_class == MediaContainer.MUSIC_ALBUM) {
                container.sort_criteria = MediaContainer.ALBUM_SORT_CRITERIA;
            }
        }

        return container;
    }

    // private methods

    /**
     * Map a DIDL attribute to a UPnP container class.
     *
     * @return A matching UPnP class for the attribute or null if it can't be
     *         mapped.
     */
    private static string? map_upnp_class (string attribute) {
        switch (attribute) {
            case "upnp:album":
                return MediaContainer.MUSIC_ALBUM;
            case "dc:creator":
            case "upnp:artist":
                return MediaContainer.MUSIC_ARTIST;
            case "dc:genre":
                return MediaContainer.MUSIC_GENRE;
            default:
                return null;
        }
    }

    /**
     * Parse a plaintext container description into a search expression.
     *
     * Also generates a name for the container and other meta-data necessary
     * for node containers.
     *
     * @param description The plaintext container description
     * @param pattern     Contains the pattern used for child containers if
     *                    descrption is for a node container, null otherwise.
     * @param attribute   Contains the UPnP attribute the container describes.
     * @param name        If passed empty, name will be generated from the
     *                    description.
     * @return A SearchExpression corresponding to the non-variable part of
     *         the description.
     */
    private static SearchExpression parse_description (string     description,
                                                       out string pattern,
                                                       out string attribute,
                                                       out string upnp_class,
                                                       ref string name) {
        var args = description.split (",");
        var expression = null as SearchExpression;
        pattern = null;
        attribute = null;
        upnp_class = null;

        int i = 0;
        while (i < args.length) {
            string previous_attribute = attribute;

            attribute = args[i].replace (QueryContainer.PREFIX, "");
            attribute = Uri.unescape_string (attribute);

            if (args[i + 1] != "?") {
                QueryContainerFactory.update_search_expression (ref expression,
                                                                args[i],
                                                                args[i + 1]);

                // We're on the end of the list, map UPnP class
                if (i + 2 == args.length) {
                    upnp_class = QueryContainerFactory.map_upnp_class
                                        (attribute);
                    if (name == "") {
                        name = Uri.unescape_string (args[i + 1]);
                    }
                }
            } else {
                args[i + 1] = "%s";
                pattern = string.joinv (",", args);

                // This container has the previouss attribute's content, so
                // use that to map the UPnP class.
                upnp_class = QueryContainerFactory.map_upnp_class
                                        (previous_attribute);

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
    private static void update_search_expression
                                        (ref SearchExpression? expression,
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
