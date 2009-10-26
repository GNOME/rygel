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

public enum Rygel.LogLevel {
    INVALID = 0,
    CRITICAL = 1,
    ERROR = 2,
    WARNING = 3,
    INFO = 4,
    DEFAULT = 4,
    DEBUG = 5
}

public class Rygel.LogHandler : GLib.Object {
    private const LogLevelFlags DEFAULT_LEVELS = LogLevelFlags.LEVEL_WARNING |
                                                 LogLevelFlags.LEVEL_CRITICAL |
                                                 LogLevelFlags.LEVEL_ERROR |
                                                 LogLevelFlags.LEVEL_MESSAGE |
                                                 LogLevelFlags.LEVEL_INFO;

    public LogLevelFlags levels; // Current log levels

    private static LogHandler log_handler; // Singleton

    public static LogHandler get_default () {
        if (log_handler == null) {
            log_handler = new LogHandler ();
        }

        return log_handler;
    }

    private LogHandler () {
        // Get the allowed log levels from the config
        var config = MetaConfig.get_default ();

        try {
            this.levels = this.log_level_to_flags (config.get_log_level ());
        } catch (Error err) {
            this.levels = DEFAULT_LEVELS;

            warning ("Failed to get log level from configuration sources: %s",
                     err.message);
        }

        Log.set_default_handler (this.log_func);
    }

    private void log_func (string?       log_domain,
                           LogLevelFlags log_levels,
                           string        message) {
        if (log_levels in this.levels) {
            // Forward the message to default domain
            Log.default_handler (log_domain, log_levels, message, null);
        }
    }

    private LogLevelFlags log_level_to_flags (LogLevel level) {
        LogLevelFlags flags = DEFAULT_LEVELS;

        switch (level) {
            case LogLevel.CRITICAL:
                flags = LogLevelFlags.LEVEL_CRITICAL;
                break;
            case LogLevel.ERROR:
                flags = LogLevelFlags.LEVEL_CRITICAL |
                        LogLevelFlags.LEVEL_ERROR;
                break;
            case LogLevel.WARNING:
                flags = LogLevelFlags.LEVEL_WARNING |
                        LogLevelFlags.LEVEL_CRITICAL |
                        LogLevelFlags.LEVEL_ERROR;
                break;
            case LogLevel.INFO:
                flags = LogLevelFlags.LEVEL_WARNING |
                        LogLevelFlags.LEVEL_CRITICAL |
                        LogLevelFlags.LEVEL_ERROR |
                        LogLevelFlags.LEVEL_MESSAGE |
                        LogLevelFlags.LEVEL_INFO;
                break;
            case LogLevel.DEBUG:
                flags = LogLevelFlags.LEVEL_WARNING |
                        LogLevelFlags.LEVEL_CRITICAL |
                        LogLevelFlags.LEVEL_ERROR |
                        LogLevelFlags.LEVEL_MESSAGE |
                        LogLevelFlags.LEVEL_INFO |
                        LogLevelFlags.LEVEL_DEBUG;
                break;
            default:
                flags = DEFAULT_LEVELS;
                break;
        }

        return flags;
    }
}
