/*
 * Copyright (C) 2013 Intel Corporation.
 * Copyright (C) 2014 Jens Georg.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
 *         Jens Georg <mail@jensge.org>
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
#include <glib/gi18n.h>

#if defined(__linux__)

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <errno.h>

#include <linux/wireless.h>

gboolean
rygel_energy_management_get_mac_and_network_type (const char *iface,
                                                  char      **mac,
                                                  char      **type) {
    int fd;
    struct ifreq ifr;
    gboolean retval = FALSE;

    g_return_val_if_fail (mac != NULL, FALSE);
    g_return_val_if_fail (type != NULL, FALSE);

    *mac = NULL;
    *type = NULL;

    fd = socket (AF_INET, SOCK_STREAM, 0);
    if (fd == -1) {
        g_warning (_("Failed to get a socket: %s"), strerror (errno));

        goto out;
    }

    strncpy (ifr.ifr_name, iface, IFNAMSIZ);
    if (ioctl (fd, SIOCGIFHWADDR, &ifr) < 0) {
        g_warning (_("Failed to get MAC address for %s: %s"),
                   iface,
                   strerror (errno));

        goto out;
    }

    *mac = g_strdup_printf ("%02X:%02X:%02X:%02X:%02X:%02X",
                            ifr.ifr_hwaddr.sa_data[0],
                            ifr.ifr_hwaddr.sa_data[1],
                            ifr.ifr_hwaddr.sa_data[2],
                            ifr.ifr_hwaddr.sa_data[3],
                            ifr.ifr_hwaddr.sa_data[4],
                            ifr.ifr_hwaddr.sa_data[5]);

    if (ioctl (fd, SIOCGIWNAME, &ifr) < 0) {
        *type = g_strdup ("Ethernet");
    } else {
        *type = g_strdup ("Wi-Fi");
    }

    retval = TRUE;
out:
    if (fd > 0) {
        close (fd);
    }

    if (*mac == NULL) {
        *mac = g_strdup ("00:00:00:00:00;00");
    }

    if (*type == NULL) {
        *type = g_strdup ("Other");
    }

    return retval;
}
#else
gboolean
rygel_energy_management_get_mac_and_network_type (const char *iface,
                                                  char      **mac,
                                                  char      **type) {
    g_warning (_("MAC and network type querying not implemented"));

    if (mac != NULL) {
        *mac = g_strdup ("00:00:00:00:00:00");
    }

    if (type != NULL) {
        *type = g_strdup ("Other");
    }

    return TRUE;
}
#endif
