/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

/**
 * A utililty class to easy searching of media objects from a bunch of
 * MediaContainer hierarchies. If search is successful, media_object is set
 * accordingly so if it's null at the completion of the search, it means that
 * search was unsuccesful. In case of error, the error field is set accordingly.
 */
internal class Rygel.MediaObjectSearch<G> : GLib.Object, Rygel.StateMachine {
    public string id;
    private ArrayList<MediaContainer> containers;
    public G data;

    public Cancellable cancellable { get; set; }

    public MediaObject media_object;
    public Error       error;

    public MediaObjectSearch (string                    id,
                              ArrayList<MediaContainer> containers,
                              G                         data,
                              Cancellable?              cancellable) {
        this.id = id;
        this.containers = containers;
        this.data = data;
        this.cancellable = cancellable;
    }

    public void run () {
        var container = this.containers.get (0);

        if (container != null) {
            container.find_object (this.id,
                                   this.cancellable,
                                   this.on_object_found);
        } else {
            this.completed ();
        }
    }

    private void on_object_found (Object?     source_object,
                                  AsyncResult res) {
        try {
            var container = source_object as MediaContainer;
            this.media_object = container.find_object_finish (res);

            if (this.media_object == null) {
                // continue the search
                this.containers.remove_at (0);

                this.run ();
            } else {
                this.completed ();
            }
        } catch (Error err) {
            this.error = err;
            this.completed ();
        }
    }
}
