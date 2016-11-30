/*
 * Copyright (C) 2012 Jens Georg <mail@jensge.org>
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

namespace Rygel.External {
    public const string MANDATORY_MISSING_MESSAGE =
        N_("External provider %s did not provide mandatory property “%s”");

    public static Variant? get_mandatory
                                    (HashTable<string, Variant> props,
                                     string                     key,
                                     string                     service_name) {
        var value = props.lookup (key);
        if (value == null) {
            warning (_(MANDATORY_MISSING_MESSAGE), service_name, key);

            return null;
        }

        return value;
    }

    public static string get_mandatory_string_value
                                    (HashTable<string, Variant> props,
                                     string                     key,
                                     string                     default,
                                     string                     service_name) {
        var value = get_mandatory (props, key, service_name);

        if (value == null) {
            return default;
        }

        return (string) value;
    }

    public static string[] get_mandatory_string_list_value
                                    (HashTable<string, Variant> props,
                                     string                     key,
                                     string[]?                  default,
                                     string                     service_name) {
        var value = get_mandatory (props, key, service_name);

        if (value == null) {
            return default;
        }

        return (string[]) value;
    }

}
