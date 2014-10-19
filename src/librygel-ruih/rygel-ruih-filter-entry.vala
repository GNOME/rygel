/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLE TELEVISION LABORATORIES
 * INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 */

protected class FilterEntry {
    private static const string LIFETIME = "lifetime";

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
