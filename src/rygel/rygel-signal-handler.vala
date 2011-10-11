/*
 * Copyright (C) 2008,2010 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using Posix;

/**
 * Handles Posix signals.
 */
public class Rygel.SignalHandler : GLib.Object {
    private static Main main = null;
    private static sigaction_t action;

    public static void setup (Main _main) {
        main = _main;

        action = sigaction_t ();

        action.sa_handler = signal_handler;

        /* Hook the handler for SIGTERM */
        sigaction (SIGINT, action, null);
        sigaction (SIGTERM, action, null);
        sigaction (SIGHUP, action, null);
    }

    public static void cleanup () {
        main = null;
    }

    private static void signal_handler (int signum) {
        if (signum == SIGHUP) {
            main.restart ();
        } else {
            main.exit (0);
        }
    }
}

