/*
 * Copyright (C) 2012 Openismus GmbH
 *
 * Author: Murray Cumming <murrayc@openismus.com>
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
 * TODO: This currently just tests instantiation.
 * We should also test how it works somehow.
 */
private class Rygel.PlaybinRendererTest : GLib.Object {
    public static int main (string[] args) {
        Gst.init (ref args);

        var test = new PlaybinRendererTest ();
        test.test_with_default_gstplaybin ();

        return 0;
    }

    public void test_with_default_gstplaybin() {
        var renderer = new Rygel.PlaybinRenderer ("test playbin renderer");
        assert (renderer != null);
        try {
            var player = Rygel.PlaybinPlayer.instance ();
            assert (player.playbin != null);
        } catch (Error error) {
            assert_not_reached ();
        }
    }
}
