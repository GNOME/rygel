/*
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * Represents Tracker SPARQL query
 */
public abstract class Rygel.TrackerQuery {
    public TrackerQueryTriplets mandatory;
    public TrackerQueryTriplets optional;

    public TrackerQuery (TrackerQueryTriplets  mandatory,
                         TrackerQueryTriplets? optional) {
        this.mandatory = mandatory;

        if (optional != null) {
            this.optional = optional;
        } else {
            this.optional = new TrackerQueryTriplets ();
        }
    }

    public abstract async void execute (TrackerResourcesIface resources)
                                        throws DBus.Error;

    // Deriving classes should override this method and complete it by
    // adding the first part of the query
    public virtual string to_string () {
        return this.serialize_triplets (this.mandatory) +
               " . " +
               this.serialize_triplets (this.optional);
    }

    private string serialize_triplets (TrackerQueryTriplets triplets) {
        string str = "";

        for (int i = 0; i < triplets.size; i++) {
            str += triplets[i].to_string ();

            if (i < triplets.size - 1) {
                if (triplets[i + 1].subject != null) {
                    str += " . ";
                } else {
                    // This implies that next triplet shares the subject with
                    // this one so we need to end this one with a semi-colon.
                    str += " ; ";
                }
            }
        }

        return str;
    }
}
