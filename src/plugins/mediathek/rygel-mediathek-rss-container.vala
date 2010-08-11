/*
 * Copyright (C) 2009 Jens Georg
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

public class Rygel.Mediathek.RssContainer : Rygel.SimpleContainer {
    private uint zdf_content_id;
    private Soup.Date last_modified = null;

    private void on_feed_got (Soup.Session session, Soup.Message msg) {
        switch (msg.status_code) {
            case 304:
                message("Feed has not changed, nothing to do");
                break;
            case 200:
                if (parse_response ((string) msg.response_body.data,
                                    (size_t) msg.response_body.length)) {
                    last_modified = new Soup.Date.from_string (
                                        msg.response_headers.get_one ("Date"));
                }
                break;
            default:
                // TODO Need to handle redirects....
                warning("Got unexpected response %u (%s)",
                        msg.status_code,
                        Soup.status_get_phrase (msg.status_code));
                break;
        }
    }

    private bool parse_response (string data, size_t length) {
        bool ret = false;
        Xml.Doc* doc = Xml.Parser.parse_memory (data, (int) length);
        if (doc != null) {
            this.children.clear ();
            this.child_count = 0;

            var ctx = new XPath.Context (doc);
            var xpo = ctx.eval ("/rss/channel/title");
            if (xpo->type == Xml.XPath.ObjectType.NODESET &&
                xpo->nodesetval->length () > 0) {
                // just use first title (there should be only one)
                this.title = xpo->nodesetval->item (0)->get_content ();
            }

            xpo = ctx.eval ("/rss/channel/item");
            if (xpo->type == Xml.XPath.ObjectType.NODESET) {
                for (int i = 0; i < xpo->nodesetval->length (); i++) {
                    Xml.Node* node = xpo->nodesetval->item (i);
                    try {
                        var item = VideoItem.create_from_xml (this, node);
                        this.add_child (item);
                        ret = true;
                    }
                    catch (VideoItemError error) {
                        warning ("Error creating video item: %s",
                                 error.message);
                    }
                }
            }
            else {
                warning ("XPath query failed");
            }

            delete doc;
            this.updated ();
        }
        else {
            warning ("Failed to parse doc");
        }

        return ret;
    }

    public void update () {
        var message = new Soup.Message ("GET",
            "http://www.zdf.de/ZDFmediathek/content/%u?view=rss".printf(
                                                            zdf_content_id)); 
        if (last_modified != null) {
            debug ("Requesting change since %s",
                   last_modified.to_string(DateFormat.HTTP));
            message.request_headers.append("If-Modified-Since", 
                   last_modified.to_string(DateFormat.HTTP));
        }

        ((RootContainer) this.parent).session.queue_message (message,
                                                             on_feed_got);
    }

    public RssContainer (MediaContainer parent, uint id) {
        base ("GroupId:%u".printf(id),
             parent, 
             "ZDF Mediathek RSS feed %u".printf (id));

        this.zdf_content_id = id;
        update ();
    }
}
