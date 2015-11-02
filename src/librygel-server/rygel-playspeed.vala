/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Craig Pratt <craig@ecaspia.com>
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

/**
 * This is a container for a PlaySpeed value.
 *
 * A Playspeed can be positive or negative whole numbers or fractions.
 * e.g. "2". "1/2", "-1/4"
 */
public class Rygel.PlaySpeed {
    public int numerator; // Sign of the speed will be attached to the numerator
    public uint denominator;

    public PlaySpeed (int numerator, uint denominator) {
        this.numerator = numerator;
        this.denominator = denominator;
    }

    public PlaySpeed.from_string (string speed) throws PlaySpeedError {
        parse (speed);
    }

    public bool equals (PlaySpeed that) {
        if (that == null) return false;

        return ( (this.numerator == that.numerator)
                 && (this.denominator == that.denominator) );
    }

    public bool is_positive () {
        return (this.numerator > 0);
    }

    public bool is_normal_rate () {
        return (this.numerator == 1) && (this.denominator == 1);
    }

    public string to_string () {
        if (this.denominator == 1) {
            return numerator.to_string ();
        } else {
            return "%d/%u".printf (this.numerator, this.denominator);
        }
    }

    public float to_float () {
        return (float) numerator / denominator;
    }

    public double to_double () {
        return (double) numerator / denominator;
    }

    private void parse (string speed) throws PlaySpeedError {
        if (!("/" in speed)) {
            this.numerator = int.parse (speed);
            this.denominator = 1;
        } else {
            var elements = speed.split ("/");
            if (elements.length != 2) {
                var msg = /*_*/("Missing/extra numerator/denominator in fraction %s");
                throw new PlaySpeedError.INVALID_SPEED_FORMAT (msg, speed);
            }
            this.numerator = int.parse (elements[0]);
            this.denominator = int.parse (elements[1]);
        }

        // "0" isn't a valid numerator or denominator (and parse returns "0" on
        // parse error)
        if (this.numerator == 0) {
            var msg = /*_*/("Invalid numerator in speed %s");
            throw new PlaySpeedError.INVALID_SPEED_FORMAT (msg.printf (speed));
        }

        if (this.denominator <= 0) {
            var msg = /*_*/("Invalid numerator in speed %s");
            throw new PlaySpeedError.INVALID_SPEED_FORMAT (msg.printf (speed));
        }
    }
}
