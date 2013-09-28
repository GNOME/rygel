/*
 * Copyright (C) 2009-2011 Jens Georg
 *
 * Author: Jens Georg <mail@jensge.org>
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

using Gee;
using Soup;
using Xml;

public class Rygel.Mediathek.RssContainer : Rygel.TrackableContainer,
                                            Rygel.SimpleContainer {
    private const string URI_TEMPLATE = "http://www.zdf.de/ZDFmediathek/" +
                                        "content/%u?view=rss";
    private uint content_id;
    private Soup.Date last_modified = null;
    private string feed_uri;

    public RssContainer (MediaContainer parent, uint id) {
        base ("GroupId:%u".printf(id),
              parent,
              "ZDF Mediathek RSS feed %u".printf (id));

        this.content_id = id;
        this.feed_uri = URI_TEMPLATE.printf (id);
        this.sort_criteria = "-dc:date,+dc:title";
        this.update.begin ();
    }

    public async void update () {
        var message = this.get_update_message ();

        // FIXME: Revert to SoupUtils once bgo#639702 is fixed
        var session = RootContainer.get_default_session ();
        SourceFunc callback = update.callback;
        session.queue_message (message, () => { callback (); });
        yield;

        switch (message.status_code) {
            case 304:
                debug ("Feed at %s did not change, nothing to do.",
                       message.uri.to_string (false));
                break;
            case 200:
                var success = yield this.parse_response (message);
                if (success) {
                    var date = message.response_headers.get_one ("Date");

                    this.last_modified = new Soup.Date.from_string (date);
                }
                break;
            default:
                warning ("Unexpected response %u for %s: %s",
                         message.status_code,
                         message.uri.to_string (false),
                         Soup.Status.get_phrase (message.status_code));
                break;
        }
    }

    private async bool parse_response (Message message) {
        var factory = VideoItemFactory.get_default ();
        unowned MessageBody response = message.response_body;

        var doc = Xml.Parser.parse_memory ((string) response.data,
                                           (int) response.length);
        if (doc == null) {
            warning ("Failed to parse XML document");

            return false;
        }
        var guard = new GUPnP.XMLDoc (doc);
        var context = new XPath.Context (guard.doc);

        var xpath_object = context.eval ("/rss/channel/title");
        if (xpath_object->type == XPath.ObjectType.NODESET &&
            xpath_object->nodesetval->length () > 0) {
            // just use first title (there should be only one)
            this.title = xpath_object->nodesetval->item (0)->get_content ();
        }
        xpath_free_object (xpath_object);

        xpath_object = context.eval ("/rss/channel/item");
        if (xpath_object->type != XPath.ObjectType.NODESET) {
            xpath_free_object (xpath_object);
            warning ("RSS feed doesn't have items");

            return false;
        }

        yield this.clear ();
        this.child_count = 0;
        for (int i = 0; i < xpath_object->nodesetval->length (); i++) {
            var node = xpath_object->nodesetval->item (i);
            try {
                var item = yield factory.create (this, node);
                if (item != null) {
                    yield this.add_child_tracked (item);
                }
            } catch (VideoItemError error) {
                debug ("Could not create video item: %s, skipping",
                       error.message);
            }
        }

        xpath_free_object (xpath_object);

        return this.child_count > 0;
    }

    private Message get_update_message () {
        var message = new Soup.Message ("GET", this.feed_uri);
        if (this.last_modified != null) {
            var datestring = this.last_modified.to_string (DateFormat.HTTP);

            debug ("Requesting change since %s", datestring);
            message.request_headers.append("If-Modified-Since", datestring);
        }

        return message;
    }

    public async void add_child (MediaObject object) {
        this.add_child_item (object as MediaItem);
    }
}
