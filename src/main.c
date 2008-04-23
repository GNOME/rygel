/*
 * Copyright (C) 2007 Zeeshan Ali.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gstreamer.net>
 * Author: Jorn Baayen <jorn@openedhand.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <stdio.h>
#include <locale.h>
#include <string.h>

#include "gui.h"
#include "upnp.h"
#include "main.h"

static gboolean light_status;
static gint     light_load_level;

void
set_status (gboolean status)
{
        if (status != light_status) {
                light_status = status;
                update_image ();

                notify_status_change (status);
        }
}

gboolean
get_status (void)
{
        return light_status;
}

void
set_load_level (gint load_level)
{
        if (load_level != light_load_level) {
                light_load_level = CLAMP (load_level, 0, 100);
                update_image ();

                notify_load_level_change (light_load_level);
        }
}

gint
get_load_level (void)
{
        return light_load_level;
}

int
main (int argc, char **argv)
{
        /* Light is off in the beginning */
        light_status = FALSE;
        light_load_level = 100;

        if (!init_ui (&argc, &argv)) {
                return -1;
        }

        if (!init_upnp ()) {
                return -2;
        }

        gtk_main ();

        deinit_ui ();
        deinit_upnp ();

        return 0;
}
