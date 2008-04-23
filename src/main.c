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
#include <gconf/gconf-client.h>
#include <uuid/uuid.h>

#include "gupnp-media-server.h"

#define DESC_DOC "xml/description.xml"
#define MODIFIED_DESC_DOC "gupnp-media-server.xml"
#define GCONF_PATH "/apps/gupnp-media-server/"

static GMainLoop *main_loop;

/* Copy-paste from gupnp. */
static xmlNode *
xml_util_get_element (xmlNode *node,
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

static GUPnPContext *
create_context (GConfClient *gconf_client,
                char        *desc_path)
{
        GUPnPContext *context;
        char *host_ip;
        int port;
        GError *error;

        error = NULL;
        host_ip = gconf_client_get_string (gconf_client,
                                           GCONF_PATH "host-ip",
                                           &error);
        if (error) {
                g_warning ("%s", error->message);

                g_error_free (error);
        }

        error = NULL;
        port = gconf_client_get_int (gconf_client,
                                     GCONF_PATH "port",
                                     &error);
        if (error) {
                g_warning ("%s", error->message);

                g_error_free (error);
        }

        error = NULL;
        context = gupnp_context_new (NULL, host_ip, port, &error);

        if (host_ip)
                g_free (host_ip);

        if (error) {
                g_warning ("Error setting up GUPnP context: %s",
                           error->message);
                g_error_free (error);

                return NULL;
        }

        /* Host UPnP dir */
        gupnp_context_host_path (context, DATA_DIR, "");

        /* Host our modified file */
        gupnp_context_host_path (context, desc_path, "/" MODIFIED_DESC_DOC);

        return context;
}

static char *
get_str_from_gconf (GConfClient *gconf_client,
                    const char  *key,
                    const char  *default_value)
{
        char *str;

        str = gconf_client_get_string (gconf_client, key, NULL);
        if (str == NULL) {
                GError *error;

                str = g_strdup (default_value);

                error = NULL;
                gconf_client_set_string (gconf_client, key, str, &error);
                if (error) {
                        g_warning ("Error setting gconf key '%s': %s.",
                                   key,
                                   error->message);

                        g_error_free (error);
                        g_free (str);

                        str = NULL;
                }
        }

        return str;
}

/* Fills the description doc @doc with a friendly name, and UDN from gconf. If
 * these keys are not present in gconf, they are set with default values */
static void
set_friendly_name_and_udn (xmlDoc      *doc,
                           GConfClient *gconf_client)
{
        xmlNode *device_element;
        xmlNode *element;
        char *str, *default_value;
        xmlChar *xml_str;
        uuid_t id;

        device_element = xml_util_get_element ((xmlNode *) doc,
                                               "root",
                                               "device",
                                               NULL);
        if (device_element == NULL) {
                g_warning ("Element /root/device not found.");

                return;
        }

        /* friendlyName */
        element = xml_util_get_element (device_element,
                                        "friendlyName",
                                        NULL);
        if (element == NULL) {
                g_warning ("Element /root/device/friendlyName not found.");

                return;
        }

        default_value = g_strdup_printf ("%s's GUPnP MediaServer",
                                         g_get_real_name ());
        str = get_str_from_gconf (gconf_client,
                                  GCONF_PATH "friendly-name",
                                  default_value);
        g_free (default_value);

        if (str == NULL) {
                return;
        }

        xml_str = xmlEncodeSpecialChars (doc, (xmlChar *) str);
        g_free (str);

        xmlNodeSetContent (element, xml_str);

        xmlFree (xml_str);

        /* UDN */
        element = xml_util_get_element (device_element,
                                        "UDN",
                                        NULL);
        if (element == NULL) {
                g_warning ("Element /root/device/UDN not found.");

                return;
        }

        default_value = g_malloc (64);
        strcpy (default_value, "uuid:");

        /* Generate new UUID */
        uuid_generate (id);
        uuid_unparse (id, default_value + 5);

        str = get_str_from_gconf (gconf_client,
                                  GCONF_PATH "UDN",
                                  default_value);
        g_free (default_value);

        if (str == NULL) {
                return;
        }

        xmlNodeSetContent (element, (xmlChar *) str);
}

static GUPnPMediaServer *
create_ms (void)
{
        GUPnPMediaServer *server;
        GUPnPContext *context;
        GConfClient *gconf_client;
        char *desc_path;
        xmlDoc *doc;
        FILE *f;
        int res;

        /* We store a modified description.xml in the user's config dir */
        desc_path = g_build_filename (g_get_user_config_dir (),
                                      MODIFIED_DESC_DOC,
                                      NULL);

        doc = xmlParseFile (DATA_DIR G_DIR_SEPARATOR_S DESC_DOC);

        if (doc == NULL)
                return NULL;

        gconf_client = gconf_client_get_default ();

        /* Modify description.xml to include a UDN and a friendy name */
        set_friendly_name_and_udn (doc, gconf_client);

        /* Save the modified description.xml into the user's config dir.
         * We do this so that we can host the modified file, and also to
         * make sure the generated UDN stays the same between sessions. */
        f = fopen (desc_path, "w+");

        if (f != NULL) {
                res = xmlDocDump (f, doc);

                fclose (f);
        }

        if (f == NULL || res == -1) {
                g_critical ("Failed to write modified"
                            " description.xml to %s.\n",
                             desc_path);

                g_free (desc_path);
                xmlFreeDoc (doc);
                g_object_unref (gconf_client);

                return NULL;
        }

        /* Set up GUPnP context */
        context = create_context (gconf_client, desc_path);
        if (!context) {
                g_free (desc_path);
                xmlFreeDoc (doc);
                g_object_unref (gconf_client);

                return NULL;
        }

        g_object_unref (gconf_client);
        g_free (desc_path);

        /* Set up the root device */
        server = gupnp_media_server_new (context,
                                         doc,
                                         MODIFIED_DESC_DOC);
        g_object_unref (context);
        g_object_weak_ref (G_OBJECT (server),
                           (GWeakNotify) xmlFreeDoc, doc);

        /* Make our device available */
        gupnp_root_device_set_available (GUPNP_ROOT_DEVICE (server), TRUE);

        return server;
}

int
main (int argc, char **argv)
{
        GUPnPMediaServer *server;

        g_type_init ();

        server = create_ms ();
        if (server == NULL) {
                return -1;
        }

        main_loop = g_main_loop_new (NULL, FALSE);
        g_main_loop_run (main_loop);

        g_main_loop_unref (main_loop);
        g_object_unref (server);

        return 0;
}

