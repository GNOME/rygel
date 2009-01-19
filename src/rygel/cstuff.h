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

#ifndef __CSTUFF_H__
#define __CSTUFF_H__

#include <libxml/tree.h>
#include <glib.h>
#include <uuid/uuid.h>

typedef void (* ApplicationExitCb)      (gpointer user_data);

G_GNUC_INTERNAL xmlNode *
get_xml_element                         (xmlNode *node,
                                         ...);

G_GNUC_INTERNAL char *
generate_random_udn                     (void);

G_GNUC_INTERNAL void
on_application_exit                     (ApplicationExitCb app_exit_cb,
                                         gpointer          user_data);

#endif /* __CSTUFF_H__ */

