/*
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Craig Pratt <craig@ecaspia.com>
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

public class Rygel.HTTPResponse : GLib.Object, Rygel.StateMachine {
    public unowned Soup.Server server { get; private set; }
    public Soup.ServerMessage msg;

    public Cancellable cancellable { get; set; }

    public HTTPSeekRequest seek;
    public PlaySpeedRequest speed;

    private SourceFunc run_continue;
    private int _priority = -1;
    public int priority {
        get {
            if (this._priority != -1) {
                return this._priority;
            }

            var mode = this.msg.get_request_headers ().get_one
                                        ("transferMode.dlna.org");

            if (mode == null || mode == "Interactive") {
                this._priority = Priority.DEFAULT;
            } else if (mode == "Streaming") {
                this._priority = Priority.HIGH;
            } else if (mode == "Background") {
                this._priority = Priority.LOW;
            } else {
                this._priority = Priority.DEFAULT;
            }

            return _priority;
        }
    }

    private DataSource src;
    private DataSink sink;
    private bool unref_soup_server;

    public HTTPResponse (HTTPGet        request,
                         HTTPGetHandler request_handler,
                         DataSource     src) throws Error {
        this.server = request.server;
        this.msg = request.msg;
        this.cancellable = request_handler.cancellable;
        this.seek = request.seek;
        this.speed = request.speed_request;
        this.src = src;
        this.sink = new DataSink (this.src, this.server, this.msg, this.seek);
        this.src.done.connect ( () => {
            this.end (false, Status.NONE);
        });
        this.src.error.connect ( (error) => {
            if (error is DataSourceError.SEEK_FAILED) {
                this.end (false,
                          Status.REQUESTED_RANGE_NOT_SATISFIABLE);
            } else {
                this.end (false, Status.NONE);
            }
        });

        if (this.cancellable != null) {
            this.cancellable.cancelled.connect (this.on_cancelled);
        }

        this.msg.get_response_body ().set_accumulate (false);

        this.server.weak_ref (this.on_server_weak_ref);
        this.unref_soup_server = true;
    }

    ~HTTPResponse () {
        if (this.unref_soup_server) {
            this.server.weak_unref (this.on_server_weak_ref);
        }
    }

    public Gee.List<HTTPResponseElement> ? preroll () throws Error {
        return this.src.preroll (this.seek, this.speed);
    }

    public async void run () {
        this.run_continue = run.callback;
        try {
            this.src.start ();
        } catch (Error error) {
            Idle.add (() => {
                this.end (false, Status.NONE);

                return false;
            });
        }

        yield;
    }

    public virtual void end (bool aborted, uint status) {
        this.src.stop ();

        var encoding = this.msg.get_response_headers ().get_encoding ();

        if (!aborted && encoding != Encoding.CONTENT_LENGTH) {
            this.msg.get_response_body ().complete ();
            this.msg.unpause ();
        }

        if (this.run_continue != null) {
            this.run_continue ();
        }

        if (status != Soup.Status.NONE) {
            this.msg.set_status (status, null);
        }

        this.completed ();
    }

    private void on_cancelled (Cancellable cancellable) {
        // FIXME - How to properly cancel this?
        this.end (true, Soup.Status.SERVICE_UNAVAILABLE);
    }

    private void on_server_weak_ref (GLib.Object object) {
        this.unref_soup_server = false;
        this.cancellable.cancel ();
    }
}
