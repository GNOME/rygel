/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 * Contact: http://www.cablelabs.com/
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

protected class FilterEntry {
    private const string LIFETIME = "lifetime";

    private string entry_name = null;
    private string entry_value = null;

    public FilterEntry (string name, string value) {
        var temp = name;
        // Get rid of extra "  in name
        temp = temp.replace ("\"", "");
        entry_name = temp;

        // Get rid of extra " in value
        temp = value;
        temp = temp.replace ("\"", "");

        // Escape regular expression symbols
        temp = Regex.escape_string (temp);
        // Convert escaped * to .* for regular expression matching (only in value)
        temp = temp.replace ("\\*", ".*");
        entry_value = temp;
    }

    public virtual bool matches (string name, string value) {
        if (this.entry_name == null && this.entry_value == null) {
            return false;
        }

        if (entry_name == name || entry_name == "*") {
            if (entry_value != null) {
                if (entry_name == LIFETIME) {
                    // Lifetime value can be negative as well.
                    return int.parse (entry_value) == int.parse (value);
                }

                var result = Regex.match_simple (entry_value, value,
                                                 RegexCompileFlags.CASELESS);

                return result;
            }
        }

        return false;
    }
}
