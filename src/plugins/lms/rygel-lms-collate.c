/*
 * Copyright (C) 2012 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

#include <glib.h>

#ifdef HAVE_UNISTRING
#   include <unistr.h>
#endif

gint rygel_lms_utf8_collate_str (const char *a, gsize alen,
                                 const char *b, gsize blen)
{
    char *a_str, *b_str;
    gint result;

    /* Make sure the passed strings are null terminated */
    a_str = g_strndup (a, alen);
    b_str = g_strndup (b, blen);

#ifdef HAVE_UNISTRING
    result = u8_strcoll (a_str, b_str);
#else
    return g_utf8_collate (a_str, b_str);
#endif

    g_free (a_str);
    g_free (b_str);

    return result;
}
