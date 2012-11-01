/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

internal class Rygel.PlaylistDatasource : Rygel.DataSource, Object {
    private MediaContainer container;
    private uint8[] data;
    private HTTPServer server;
    private ClientHacks hacks;

    public PlaylistDatasource (MediaContainer container,
                               HTTPServer     server,
                               ClientHacks?   hacks) {
        this.container = container;
        this.server = server;
        this.hacks = hacks;
        this.generate_data.begin ();
    }

    public signal void data_ready ();

    public void start (HTTPSeek? offsets) throws Error {
        if (this.data == null) {
            this.data_ready.connect ( () => {
                try {
                    this.start (offsets);
                } catch (Error error) { }
            });

            return;
        }

        Idle.add ( () => {
            this.data_available (this.data);
            this.done ();
            return false;
        });
    }

    public void freeze () { }

    public void thaw () { }

    public void stop () { }

    public async void generate_data () {
        try {
            var sort_criteria = this.container.sort_criteria;
            var count = this.container.child_count;

            var children = yield this.container.get_children (0,
                                                              count,
                                                              sort_criteria,
                                                              null);

            if (children != null) {
                debug ("Found %d children", children.size);
                var serializer = new Serializer (SerializerType.DIDL_S);
                children.serialize (serializer, this.server, this.hacks);

                var xml = serializer.get_string ();

                this.data = xml.data;
                this.data_ready ();
            }
        } catch (Error error) {
            warning ("COuld not generate playlist: %s", error.message);
            this.error (error);
        }
    }
}

internal class Rygel.HTTPPlaylistHandler : Rygel.HTTPGetHandler {
    public HTTPPlaylistHandler (Cancellable? cancellable) {
        this.cancellable = cancellable;
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        try {
            var source = new PlaylistDatasource
                                        (request.object as MediaContainer,
                                         request.http_server,
                                         request.hack);

            return new HTTPResponse (request,this, source);
        } catch (Error error) {
            throw new HTTPRequestError.NOT_FOUND (error.message);
        }
    }

    protected override DIDLLiteResource add_resource (DIDLLiteItem didl_item,
                                                      HTTPGet      request) {
        // TODO: Implement
        return null as DIDLLiteResource;
    }
}
