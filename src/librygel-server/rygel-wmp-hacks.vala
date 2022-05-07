/*
 * Copyright (C) 2012 Nokia Corporation.
 *
 * Author: Lukasz Pawlik <lukasz.pawlik@comarch.com>
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

using Soup;

internal class Rygel.WMPHacks : ClientHacks {
    private const string AGENT = ".*Windows-Media-Player/12\\.0.*";

    public WMPHacks (ServerMessage? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override async MediaObjects? search
                                        (SearchableContainer container,
                                         SearchExpression?   expression,
                                         uint                offset,
                                         uint                requested,
                                         string              sort_criteria,
                                         Cancellable?        cancellable,
                                         out uint            total_matches)
                                         throws Error {
        // Drop the limit. WMP has a problem if we don't know the number of
        // total matches; instead of continuing to request items it stoppes
        // after the first batch. Luckily it only searches to get all the
        // items of the server anyway and it is broken enough that it accepts
        // that we return too many items.
        return yield container.search (expression,
                                       offset,
                                       0,
                                       sort_criteria,
                                       cancellable,
                                       out total_matches);
    }
}
