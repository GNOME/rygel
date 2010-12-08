/*
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Author: Sunil Mohan Adapa <sunil@medhas.org>
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

/**
 * Logical expressions in SPARQL query filter
 */
public class Rygel.Tracker.LogicalFilter : Object, QueryFilter {
    public enum Operator {
        AND,
        OR,
        NOT
    }

    public Operator op;
    public QueryFilter operand1;
    public QueryFilter operand2;

    public LogicalFilter (Operator     op,
                          QueryFilter  operand1,
                          QueryFilter? operand2 = null) {
        this.op = op;
        this.operand1 = operand1;
        this.operand2 = operand2;
    }

    /**
     * Creates a simplified version of this expressions if it involves boolean
     * constants.
     */
    public QueryFilter simplify () {
        if (!(this.operand1 is BooleanFilter ||
              this.operand2 is BooleanFilter)) {
            return this;
        }

        if (this.op == Operator.NOT && this.operand1 is BooleanFilter) {
            var bool_filter = this.operand1 as BooleanFilter;

            bool_filter.value = !(bool_filter.value);

            return this.operand1;
        }

        BooleanFilter bool_filter;
        QueryFilter operand;

        if (this.operand1 is BooleanFilter) {
            bool_filter = this.operand1 as BooleanFilter;
            operand = this.operand2;
        } else {
            bool_filter = this.operand2 as BooleanFilter;
            operand = this.operand1;
        }

        if ((bool_filter.value && this.op == Operator.OR) ||
            (!(bool_filter.value) && this.op == Operator.AND)) {
            return bool_filter;
        } else {
            return operand;
        }
    }

    public string to_string () {
        string str = "(" + this.operand1.to_string () + ")";

        if (this.op == Operator.NOT) {
            return "!" + str;
        }

        switch (this.op) {
        case Operator.AND:
            str += " && ";

            break;
        case Operator.OR:
            str += " || ";

            break;
        default:
            assert_not_reached ();
        }

        str += "(" + this.operand2.to_string () + ")";

        return str;
    }
}
