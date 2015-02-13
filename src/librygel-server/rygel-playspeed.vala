/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLE TELEVISION LABORATORIES
 * INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
            return this.numerator.to_string () + "/" + this.denominator.to_string ();
        }
    }

    public float to_float () {
        return (float)numerator/denominator;
    }

    public double to_double () {
        return (double)numerator/denominator;
    }

    private void parse (string speed) throws PlaySpeedError {
        if (! ("/" in speed)) {
            this.numerator = int.parse (speed);
            this.denominator = 1;
        } else {
            var elements = speed.split ("/");
            if (elements.length != 2) {
                throw new PlaySpeedError.INVALID_SPEED_FORMAT ("Missing/extra numerator/denominator");
            }
            this.numerator = int.parse (elements[0]);
            this.denominator = int.parse (elements[1]);
        }
        // "0" isn't a valid numerator or denominator (and parse returns "0" on parse error)
        if (this.numerator == 0) {
            throw new PlaySpeedError.INVALID_SPEED_FORMAT ("Invalid numerator in speed: " + speed);
        }
        if (this.denominator <= 0) {
            throw new PlaySpeedError.INVALID_SPEED_FORMAT ("Invalid denominator in speed: " + speed);
        }
    }
}
