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

public enum Rygel.LogicalOperator {
    AND,
    OR
}

// Represents a search expression that consists of two search expressions joined
// by a logical operator
public class Rygel.LogicalExpression :
             Rygel.SearchExpression<LogicalOperator,
                                    SearchExpression,
                                    SearchExpression> {
    public override bool satisfied_by (MediaObject media_object) {
        switch (this.op) {
        case LogicalOperator.AND:
            return this.operand1.satisfied_by (media_object) &&
                   this.operand2.satisfied_by (media_object);
        case LogicalOperator.OR:
            return this.operand1.satisfied_by (media_object) ||
                   this.operand2.satisfied_by (media_object);
        default:
            return false;
        }
    }

    public override string to_string () {
        return "(%s %d %s)".printf (this.operand1.to_string (),
                                    this.op,
                                    this.operand2.to_string ());
    }
}
