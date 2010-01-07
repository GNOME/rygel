/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

errordomain Rygel.SearchCriteriaError {
    SYNTAX_ERROR
}

private struct Rygel.SearchCriteriaSymbol {
    public string symbol;
    public int value;
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

    private Scanner scanner;
    private enum Symbol {
        ASTERISK = TokenType.LAST + 11,
        AND      = TokenType.LAST + 12,
        OR       = TokenType.LAST + 13,
        TRUE     = TokenType.LAST + 14,
        FALSE    = TokenType.LAST + 15
    }

    private const SearchCriteriaSymbol[] symbols = {
        { "*",              (int) Symbol.ASTERISK },
        { "and",            (int) Symbol.AND },
        { "or",             (int) Symbol.OR },
        { "=",              (int) SearchCriteriaOp.EQ },
        { "!=",             (int) SearchCriteriaOp.NEQ },
        { "<",              (int) SearchCriteriaOp.LESS },
        { "<=",             (int) SearchCriteriaOp.LEQ },
        { ">",              (int) SearchCriteriaOp.GREATER },
        { ">=",             (int) SearchCriteriaOp.GEQ },
        { "contains",       (int) SearchCriteriaOp.CONTAINS },
        { "doesNotContain", (int) SearchCriteriaOp.DOES_NOT_CONTAIN },
        { "derivedfrom",    (int) SearchCriteriaOp.DERIVED_FROM },
        { "exists",         (int) SearchCriteriaOp.EXISTS },
        { "true",           (int) Symbol.TRUE },
        { "false",          (int) Symbol.FALSE }
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

        foreach (SearchCriteriaSymbol s in symbols) {
            scanner.scope_add_symbol (0, s.symbol, s.value.to_pointer ());
        }
    }

    // This implementation is not really async
    public async void run () {
        if (this.str == "*") {
            // Wildcard
            this.completed ();
        }

        this.scanner.input_text (this.str, (uint) this.str.length);
        this.scanner.get_next_token ();
        try {
            this.expression = this.or_expression ();
        } catch (Error err) {
            this.err = err;
        }
        this.completed ();
    }

    private SearchExpression? and_expression () throws Error {
        var exp = relational_expression ();
        while (this.scanner.token == (int) Symbol.AND) {
            this.scanner.get_next_token ();
            var exp2 = new LogicalExpression();
            exp2.operand1 = exp;
            exp2.op = LogicalOperator.AND;
            exp2.operand2 = relational_expression ();
            exp = exp2;
        }

        return exp;
    }

    private SearchExpression? relational_expression () throws Error {
        var exp = new RelationalExpression ();
        if (this.scanner.token == TokenType.IDENTIFIER) {
            exp.operand1 = this.scanner.value.identifier;
            this.scanner.get_next_token ();
            if (this.scanner.token == (int) SearchCriteriaOp.EQ ||
                this.scanner.token == (int) SearchCriteriaOp.NEQ ||
                this.scanner.token == (int) SearchCriteriaOp.LESS ||
                this.scanner.token == (int) SearchCriteriaOp.LEQ ||
                this.scanner.token == (int) SearchCriteriaOp.GREATER ||
                this.scanner.token == (int) SearchCriteriaOp.GEQ ||
                this.scanner.token == (int) SearchCriteriaOp.CONTAINS ||
                this.scanner.token == (int) SearchCriteriaOp.DOES_NOT_CONTAIN ||
                this.scanner.token == (int) SearchCriteriaOp.DERIVED_FROM) {
               exp.op = (SearchCriteriaOp) this.scanner.token;
               this.scanner.get_next_token ();
               if (this.scanner.token == TokenType.STRING) {
                   exp.operand2 = this.scanner.value.string;
                   this.scanner.get_next_token ();

                   return exp;
               } else {
                    throw new SearchCriteriaError.SYNTAX_ERROR (
                                 "relational_expression: expected \"string\"");
               }
            } else if (this.scanner.token == (int) SearchCriteriaOp.EXISTS) {
                exp.op = (SearchCriteriaOp) this.scanner.token;
                this.scanner.get_next_token ();
                if (this.scanner.token == (int) Symbol.TRUE) {
                    exp.operand2 = "true";
                    this.scanner.get_next_token ();

                    return exp;
                } else if (this.scanner.token == (int) Symbol.FALSE) {
                    exp.operand2 = "false";
                    this.scanner.get_next_token ();

                    return exp;
                } else {
                    throw new SearchCriteriaError.SYNTAX_ERROR (
                                 "relational_expression: expected true|false");
                }
            } else {
                throw new SearchCriteriaError.SYNTAX_ERROR (
                                   "relational_expression: expected operator");
            }
        } else if (this.scanner.token == TokenType.LEFT_PAREN) {
            this.scanner.get_next_token ();
            var exp2 = this.or_expression ();
            if (this.scanner.token != TokenType.RIGHT_PAREN) {
                throw new SearchCriteriaError.SYNTAX_ERROR (
                                          "relational_expression: expected )");
            } else {
                this.scanner.get_next_token ();

                return exp2;
            }

        } else {
            throw new SearchCriteriaError.SYNTAX_ERROR (
                            "relational_expression: expected identifier or (");
        }
    }

    private SearchExpression? or_expression () throws Error {
        var exp = and_expression ();
        while (this.scanner.token == (int) Symbol.OR) {
            this.scanner.get_next_token ();
            var exp2 = new LogicalExpression();
            exp2.operand1 = exp;
            exp2.op = LogicalOperator.OR;
            exp2.operand2 = and_expression ();
            exp = exp2;
        }

        return exp;
    }

}

