/*
 * Copyright (C) 2013 Jens Georg <mail@jensge.org>
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
using GUPnP;

/**
 * Hacks class to accept seeks that are invalid according to DLNA.
 *
 * Some devices always request the full range on a non-seekable stream, be it
 * transcoded or live, regardless of what DLNA.ORG_OP says. This hack just
 * accepts this seek request.
 *
 * Supported devices are:
 *  - Onkyo (Mediabolic-IMHTTP)
 *  - PS3
 *  - Sharp TVs
 *  - WD TV Live (alphanetworks)
 *  - Musical Fidelity/Marantz devices (KnOS/3.2)
 *
 * Samsung devices are also affected but they need other hacks as well to
 * that's handled in the Samsung-specific class.
 */
internal class Rygel.SeekHacks : ClientHacks {
    private const string AGENT = ".*Mediabolic-IMHTTP.*|" +
                                 ".*PLAYSTATION 3.*|" +
                                 ".*SHARP-AQUOS-DMP.*|" +
                                 ".*alphanetworks.*|" +
                                 ".*KnOS/3.2.*";

    public SeekHacks (ServerMessage? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override bool force_seek () {
        return true;
    }
}
