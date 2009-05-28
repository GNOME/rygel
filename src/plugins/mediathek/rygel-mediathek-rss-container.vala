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
using Rygel;
using Xml;

public class Rygel.MediathekRssContainer : MediaContainer {
    private ArrayList<MediaItem> items;
    private uint zdf_content_id;
    private Soup.Date last_modified = null;

    private void on_feed_got (Soup.Session session, Soup.Message msg) {
        switch (msg.status_code) {
            case 304:
                message("Feed has not changed, nothing to do");
                break;
            case 200:
                if (parse_response (msg.response_body.data, 
                                    (size_t) msg.response_body.length)) {
                    last_modified = new Soup.Date.from_string(
                                            msg.response_headers.get ("Date"));
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
            items.clear ();
            var ctx = new XPathContext (doc);
            var xpo = ctx.eval ("/rss/channel/title");
            if (xpo->type == Xml.XPathObjectType.NODESET &&
                xpo->nodesetval->length () > 0) {
                // just use first title (there should be only one)
                this.title = xpo->nodesetval->item (0)->get_content ();
            }

            xpo = ctx.eval ("/rss/channel/item");
            if (xpo->type == Xml.XPathObjectType.NODESET) {
                for (int i = 0; i < xpo->nodesetval->length (); i++) {
                    Xml.Node* node = xpo->nodesetval->item (i);
                    try {
                        var item = 
                                MediathekVideoItem.create_from_xml (this, 
                                                                    node);
                        this.items.add (item);
                        ret = true;
                    }
                    catch (MediathekVideoItemError error) {
                        warning ("Error creating video item: %s",
                                 error.message);
                    }
                }
            }
            else {
                warning ("XPath query failed");
            }

            delete doc;
            this.child_count = items.size;
            this.updated ();
        }
        else {
            warning ("Failed to parse doc");
        }

        return ret;
    }

    public override void get_children (uint offset, 
                                       uint max_count, 
                                       Cancellable? cancellable, 
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);
        var children = this.items.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>> (this,
                                                                    callback);
        res.data = children;
        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                            AsyncResult res)
                                                            throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;

        return simple_res.data;
    }

    public override void find_object (string id, 
                                      Cancellable? cancellable, 
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<string> (this,
                                                       callback);

        res.data = id;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res) 
                                                     throws GLib.Error {
        var id = ((Rygel.SimpleAsyncResult<string>) res).data;
        return find_object_sync (id);
    }

    public MediaObject? find_object_sync (string id) {
        MediaItem item = null;
        foreach (MediaItem tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;
                break;
            }
        }

        return item;
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

        ((MediathekRootContainer) this.parent).session.queue_message (
                                                                  message, 
                                                                  on_feed_got);
    }

    public MediathekRssContainer (MediaContainer parent, uint id) {
        base ("GroupId:%u".printf(id), 
             parent, 
             "ZDF Mediathek RSS feed %u".printf(id), 
             0);
        this.items = new ArrayList<MediaItem> ();
        this.child_count = 0;
        this.zdf_content_id = id;
        update ();
    }
}
