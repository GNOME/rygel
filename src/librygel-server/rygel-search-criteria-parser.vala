/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

errordomain Rygel.SearchCriteriaError {
    SYNTAX_ERROR
}

private enum Rygel.SearchCriteriaSymbol {
    EQ = SearchCriteriaOp.EQ,
    NEQ,
    LESS,
    LEQ,
    GREATER,
    GEQ,
    CONTAINS,
    DOES_NOT_CONTAIN,
    DERIVED_FROM,
    EXISTS,

    ASTERISK,
    AND,
    OR,
    TRUE,
    FALSE
}

private struct Rygel.SearchCriteriaToken {
    public string str_symbol;
    public SearchCriteriaSymbol symbol;
}

/**
 * Parses a search criteria string and creates SearchExpression as a result.
 */
internal class Rygel.SearchCriteriaParser : Object, StateMachine {
    // The original string representation received from client
    public string str;
    public SearchExpression expression; // The root expression
    public Error err;

    public Cancellable cancellable { get; set; }

    private SearchCriteriaSymbol token {
        get {
            return (SearchCriteriaSymbol) this.scanner.token;
        }
    }

    private string context {
        owned get {
            return this.scanner.line.to_string () + "." +
                   this.scanner.position.to_string ();
        }
    }

    private Scanner scanner;

    private const SearchCriteriaToken[] TOKENS = {
        { "=",              SearchCriteriaSymbol.EQ },
        { "!=",             SearchCriteriaSymbol.NEQ },
        { "<",              SearchCriteriaSymbol.LESS },
        { "<=",             SearchCriteriaSymbol.LEQ },
        { ">",              SearchCriteriaSymbol.GREATER },
        { ">=",             SearchCriteriaSymbol.GEQ },
        { "contains",       SearchCriteriaSymbol.CONTAINS },
        { "doesNotContain", SearchCriteriaSymbol.DOES_NOT_CONTAIN },
        { "derivedfrom",    SearchCriteriaSymbol.DERIVED_FROM },
        { "exists",         SearchCriteriaSymbol.EXISTS },
        { "*",              SearchCriteriaSymbol.ASTERISK },
        { "and",            SearchCriteriaSymbol.AND },
        { "or",             SearchCriteriaSymbol.OR },
        { "true",           SearchCriteriaSymbol.TRUE },
        { "false",          SearchCriteriaSymbol.FALSE }
    };

    public SearchCriteriaParser (string str) throws Error {
        this.str = str;
        scanner = new Scanner (null);
        scanner.config.cset_skip_characters = " \t\n\r\012" +
                                              "\013\014\015";
        scanner.config.scan_identifier_1char = true;
        scanner.config.cset_identifier_first = CharacterSet.a_2_z +
                                               "_*<>=!@" +
                                               CharacterSet.A_2_Z;
        scanner.config.cset_identifier_nth   = CharacterSet.a_2_z + "_" +
                                               CharacterSet.DIGITS + "=:@" +
                                               CharacterSet.A_2_Z +
                                               CharacterSet.LATINS +
                                               CharacterSet.LATINC;
        scanner.config.symbol_2_token        = true;

        foreach (var token in TOKENS) {
            scanner.scope_add_symbol (0,
                                      token.str_symbol,
                                      ((int) token.symbol).to_pointer ());
        }
    }

    // This implementation is not really async
    public async void run () {
        if (this.str == "*") {
            // Wildcard
            this.completed ();

            return;
        }

        this.scanner.input_text (this.str, (uint) this.str.length);
        this.scanner.get_next_token ();
        try {
            this.expression = this.parse_or_expression ();
        } catch (Error err) {
            this.err = err;
        }
        this.completed ();
    }

    private SearchExpression? parse_and_expression () throws Error {
        var exp = this.parse_rel_expression ();
        while (this.token == SearchCriteriaSymbol.AND) {
            this.scanner.get_next_token ();
            var exp2 = new LogicalExpression();
            exp2.operand1 = exp;
            exp2.op = LogicalOperator.AND;
            exp2.operand2 = this.parse_rel_expression ();
            exp = exp2;
        }

        return exp;
    }

    private SearchExpression? parse_rel_expression () throws Error {
        var exp = new RelationalExpression ();
        if (this.scanner.token == TokenType.IDENTIFIER) {
            exp.operand1 = this.scanner.value.identifier;
            this.scanner.get_next_token ();

            if (this.token == SearchCriteriaSymbol.DERIVED_FROM) {
                if (exp.operand1 != "upnp:class") {
                    throw new SearchCriteriaError.SYNTAX_ERROR (this.context +
                        ": \"derivedFrom\" requires \"upnp:class\" lhs");
                }
            }

            if (this.token == SearchCriteriaSymbol.EQ ||
                this.token == SearchCriteriaSymbol.NEQ ||
                this.token == SearchCriteriaSymbol.LESS ||
                this.token == SearchCriteriaSymbol.LEQ ||
                this.token == SearchCriteriaSymbol.GREATER ||
                this.token == SearchCriteriaSymbol.GEQ ||
                this.token == SearchCriteriaSymbol.CONTAINS ||
                this.token == SearchCriteriaSymbol.DOES_NOT_CONTAIN ||
                this.token == SearchCriteriaSymbol.DERIVED_FROM) {
                exp.op = (SearchCriteriaOp) this.scanner.token;
                this.scanner.get_next_token ();
               if (this.scanner.token == TokenType.STRING) {
                   exp.operand2 = this.scanner.value.string;
                   this.scanner.get_next_token ();

                   return exp;
               } else {
                    throw new SearchCriteriaError.SYNTAX_ERROR (this.context +
                                                                ": expected " +
                                                                "\"STRING\"");
               }
            } else if (this.token == SearchCriteriaSymbol.EXISTS) {
                exp.op = (SearchCriteriaOp) this.scanner.token;
                this.scanner.get_next_token ();
                if (this.token == SearchCriteriaSymbol.TRUE) {
                    exp.operand2 = "true";
                    this.scanner.get_next_token ();

                    return exp;
                } else if (this.token == SearchCriteriaSymbol.FALSE) {
                    exp.operand2 = "false";
                    this.scanner.get_next_token ();

                    return exp;
                } else {
                    throw new SearchCriteriaError.SYNTAX_ERROR (this.context +
                                                                ": expected " +
                                                                "\"true\"|\"" +
                                                                "false\"");
                }
            } else {
                throw new SearchCriteriaError.SYNTAX_ERROR (this.context +
                                                            ": expected " +
                                                            "operator");
            }
        } else if (this.scanner.token == TokenType.LEFT_PAREN) {
            this.scanner.get_next_token ();
            var exp2 = this.parse_or_expression ();
            if (this.scanner.token != TokenType.RIGHT_PAREN) {
                throw new SearchCriteriaError.SYNTAX_ERROR (this.context +
                                                            ": expected ')'");
            } else {
                this.scanner.get_next_token ();

                return exp2;
            }

        } else {
            throw new SearchCriteriaError.SYNTAX_ERROR (this.context +
                                                        ": expected " +
                                                        "identifier or '('");
        }
    }

    private SearchExpression? parse_or_expression () throws Error {
        var exp = this.parse_and_expression ();
        while (this.token == SearchCriteriaSymbol.OR) {
            this.scanner.get_next_token ();
            var exp2 = new LogicalExpression();
            exp2.operand1 = exp;
            exp2.op = LogicalOperator.OR;
            exp2.operand2 = this.parse_and_expression ();
            exp = exp2;
        }

        return exp;
    }

}
