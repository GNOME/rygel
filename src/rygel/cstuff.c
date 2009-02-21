/*
 * Copyright (C) 2008 Zeeshan Ali.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 * Author: Jorn Baayen <jorn@openedhand.com>
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

#include <cstuff.h>
#include <signal.h>
#include <string.h>

static ApplicationExitCb on_app_exit = NULL;
static gpointer data;
static struct sigaction sig_action;

/* Copy-paste from gupnp. */
xmlNode *
get_xml_element (xmlNode *node,
                 ...)
{
        va_list var_args;

        va_start (var_args, node);

        while (TRUE) {
                const char *arg;

                arg = va_arg (var_args, const char *);
                if (!arg)
                        break;

                for (node = node->children; node; node = node->next)
                        if (!strcmp (arg, (char *) node->name))
                                break;

                if (!node)
                        break;
        }

        va_end (var_args);

        return node;
}

char *
generate_random_udn (void)
{
        char *str, *default_value;
        uuid_t id;

        default_value = g_malloc (64);
        strcpy (default_value, "uuid:");

        /* Generate new UUID */
        uuid_generate (id);
        uuid_unparse (id, default_value + 5);

        return default_value;
}

static void
signal_handler (int signum)
{
        on_app_exit (data);
}

void
on_application_exit (ApplicationExitCb app_exit_cb,
                     gpointer          user_data)
{
        on_app_exit = app_exit_cb;
        data = user_data;

        /* Hook the handler for SIGTERM */
        memset (&sig_action, 0, sizeof (sig_action));
        sig_action.sa_handler = signal_handler;
        sigaction (SIGINT, &sig_action, NULL);
}

