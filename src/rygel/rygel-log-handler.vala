/*
 * Copyright (C) 2008 Nokia Corporation.
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

public class Rygel.LogHandler : GLib.Object {
    public const string DOMAIN = "Rygel";
    private const LogLevelFlags DEFAULT_LEVELS = LogLevelFlags.LEVEL_WARNING |
                                                 LogLevelFlags.LEVEL_CRITICAL |
                                                 LogLevelFlags.LEVEL_ERROR;

    public LogLevelFlags levels; // Current log levels

    private static LogHandler log_handler; // Singleton

    public static LogHandler get_default () {
        if (log_handler == null) {
            log_handler = new LogHandler ();
        }

        return log_handler;
    }

    private LogHandler () {
        Log.set_handler (DOMAIN,
                         LogLevelFlags.LEVEL_MASK |
                         LogLevelFlags.FLAG_FATAL |
                         LogLevelFlags.FLAG_RECURSION,
                         this.log_func);

        this.levels = DEFAULT_LEVELS;
    }

    private void log_func (string?       log_domain,
                           LogLevelFlags log_levels,
                           string        message) {
        assert (log_domain == DOMAIN);

        if (log_levels in this.levels) {
            // Just forward the message to default domain for now
            log (null, log_levels, message);
        }
    }
}
