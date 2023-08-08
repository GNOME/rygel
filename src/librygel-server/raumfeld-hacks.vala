// SPDX-License-Identifier: LGPL-2.1-or-later
// SPDX-FileCopyrightText: 2003 Jens Georg <mail@jensge.org>

using Soup;
using GUPnP;

internal class Rygel.RaumfeldHacks : ClientHacks {

    // FIXME: Blergh. Way too generic
    private const string AGENT = ".*Raum[fF]eld.*|.*souphttpsrc.*";

    public RaumfeldHacks (ServerMessage? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override void apply (MediaObject object) {
        foreach (var resource in object.get_resource_list ()) {
            if (resource.mime_type == "audio/x-vorbis+ogg" ||
                resource.mime_type == "audio/x-flac+ogg") {
                resource.mime_type = "audio/ogg";
            }
        }
    }
}