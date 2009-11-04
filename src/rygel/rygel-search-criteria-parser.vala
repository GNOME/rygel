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

/**
 * Parses a search criteria string and creates SearchExpression as a result.
 */
internal class Rygel.SearchCriteriaParser : Object, StateMachine {
    // The original string representation received from client
    public string str;
    public SearchExpression expression; // The root expression
    public Error err;

    private LinkedList<SearchExpression> exp_stack;

    public Cancellable cancellable { get; set; }

    public SearchCriteriaParser (string str) throws Error {
        this.str = str;
        this.exp_stack = new LinkedList<SearchExpression> ();
    }

    // This implementation is not really async
    public async void run () {
        var parser = new GUPnP.SearchCriteriaParser ();

        parser.expression.connect (this.on_expression);
        parser.begin_parens.connect (() => {
            this.exp_stack.offer_tail (new OpenningBrace ());
        });
        parser.end_parens.connect (this.on_end_parens);
        parser.conjunction.connect (() => {
            this.handle_logical_operator (LogicalOperator.AND);
        });
        parser.disjunction.connect (() => {
            this.handle_logical_operator (LogicalOperator.OR);
        });

        try {
            parser.parse_text (this.str);
        } catch (Error err) {
            this.err = err;
        }

        this.completed ();
    }

    private bool on_expression (GUPnP.SearchCriteriaParser parser,
                                string                     property,
                                SearchCriteriaOp           op,
                                string                     value,
                                void                      *err) {
        // Atomic expression from out POV
        var expression = new AtomicExpression ();
        expression.op = op;
        expression.operand1 = property;
        expression.operand2 = value;

        // Now lets decide where to place this expression
        var stack_top = this.exp_stack.peek_tail ();
        if (stack_top == null) {
            if (this.expression == null) {
                // Top-level expression
                this.expression = expression;
            } else if (this.expression is LogicalExpression) {
                // The previous expression must have lacked the 2nd operand
                var l_expression = this.expression as LogicalExpression;
                l_expression.operand2 = expression;
            }
        } else if (stack_top is OpenningBrace) {
            this.exp_stack.offer_tail (expression);
        } else if (stack_top is LogicalExpression) {
            // The previous expression must have lacked the 2nd operand
            var l_expression = stack_top as LogicalExpression;
            l_expression.operand2 = expression;
        }

        return true;
    }

    private void handle_logical_operator (LogicalOperator lop) {
        var expression = new LogicalExpression ();
        expression.op = lop;

        var stack_top = this.exp_stack.peek_tail ();
        if (stack_top != null) {
            this.exp_stack.poll_tail (); // Pop last expression
            this.exp_stack.poll_tail (); // Pop opening brace

            // Put new Logical expression on the top of the stack
            this.exp_stack.offer_tail (expression);

            // Make the previous expression on the stack it's first argument
            expression.operand1 = stack_top;
        } else {
            // Nothing on the stack? This must mean this is a logical expression
            // combining the expression tree and the next expression that we
            // haven't yet parsed.
            expression.operand1 = this.expression;
            this.expression = expression;
        }
    }

    private void on_end_parens (GUPnP.SearchCriteriaParser parser) {
        // Closing parenthesis means the expression on the stack is complete so
        // first we pop that from the stack.
        var inner_exp = this.exp_stack.poll_tail ();
        var outer_exp = this.exp_stack.peek_tail () as LogicalExpression;
        if (outer_exp == null) {
            // Stack is now empty, go for the expression tree!
            if (this.expression != null) {
                outer_exp = this.expression as LogicalExpression;
            } else {
                this.expression = inner_exp;
            }
        }

        if (outer_exp != null) {
            // Either there was an incomplete expression either on the stack
            // or the expression tree so we just complete that.
            outer_exp.operand2 = inner_exp;
        }
    }
}

// FIXME: Braces are not really expressions so we must stop using these
// classes as soon as we figure a way to not use the same stack for expressions
// and braces.
private class Rygel.OpenningBrace: Rygel.SearchExpression<void *,
                                                          void *,
                                                          void *> {
    public override bool satisfied_by (MediaObject media_object) {
        assert_not_reached ();
    }

    public override string to_string () {
        assert_not_reached ();
    }
}

private class Rygel.ClosingBrace: Rygel.SearchExpression<void *,
                                                         void *,
                                                         void *> {
    public override bool satisfied_by (MediaObject media_object) {
        assert_not_reached ();
    }

    public override string to_string () {
        assert_not_reached ();
    }
}

