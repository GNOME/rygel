/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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

/**
 * Represents SearchCriteria string in Search action of ContentDirectory.
 */
public class Rygel.SearchCriteria : GLib.Object {
    // The original string representation received from client
    public string str;

    public SearchExpression expression; // The root expression

    internal SearchCriteria (string           str,
                             SearchExpression expression)
                             throws Error {
        this.str = str;
        this.expression = expression;
    }

    public bool fullfills (MediaObject media_object) {
        return true;
    }
}

public enum Rygel.LogicalOperator {
    AND,
    OR
}

public class Rygel.SearchExpression<G,H,I> {
    public G op; // Operator

    public H operand1;
    public I operand2;
}

public class Rygel.AtomicExpression :
              Rygel.SearchExpression<SearchCriteriaOp,string,string> {}

public class Rygel.LogicalExpression :
              Rygel.SearchExpression<LogicalOperator,
                                     SearchExpression,
                                     SearchExpression> {}

// FIXME: Braces are not really expressions so we must stop using these
// classes as soon as we figure a way to not use the same stack for expressions
// and braces.
internal class Rygel.OpenningBrace: Rygel.SearchExpression<void *,
                                                           void *,
                                                           void *> {}
internal class Rygel.ClosingBrace: Rygel.SearchExpression<void *,
                                                          void *,
                                                          void *> {}
