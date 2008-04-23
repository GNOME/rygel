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
#define DEFAULT_PORT 2700

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
create_context (char *desc_path)
{
        GUPnPContext *context;
        GConfClient *gconf_client;
        char *host_ip;
        int port;
        GError *error;

        gconf_client = gconf_client_get_default ();

        error = NULL;
        host_ip = gconf_client_get_string (gconf_client,
                                           GCONF_PATH "host-ip",
                                           &error);
        if (host_ip == NULL) {
                host_ip = g_strdup (g_get_host_name ());

                if (error) {
                        g_warning ("%s", error->message);

                        g_error_free (error);
                }
        }

        error = NULL;
        port = gconf_client_get_int (gconf_client,
                                     GCONF_PATH "port",
                                     &error);
        if (error) {
                port = DEFAULT_PORT;

                g_warning ("%s", error->message);
                g_warning ("Failed to get port from configuration."
                           " Assuming default: %d", port);

                g_error_free (error);
        }

        g_object_unref (gconf_client);

        error = NULL;
        context = gupnp_context_new (NULL, host_ip, port, &error);

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

/* Fills the description doc @doc with a friendly name, including
 * the full name of the user, and a UDN if not already present. */
static void
set_friendly_name_and_udn (xmlDoc *doc)
{
        xmlNode *device_element;
        xmlNode *element;
        char *str;
        xmlChar *xml_str;

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

        str = g_strdup_printf ("%s's GUPnP MediaServer", g_get_real_name ());
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

        xml_str = xmlNodeGetContent (element);
        if (!xml_str || strncmp ((char *) xml_str, "uuid:", 5)) {
                uuid_t id;
                char out[44];

                strcpy (out, "uuid:");

                /* Generate new UUID */
                uuid_generate (id);
                uuid_unparse (id, out + 5);

                xmlNodeSetContent (element, (xmlChar *) out);
        }

        if (xml_str)
                xmlFree (xml_str);
}

static GUPnPMediaServer *
create_ms (void)
{
        GUPnPMediaServer *server;
        GUPnPContext *context;
        char *desc_path;
        xmlDoc *doc;
        FILE *f;
        int res;

        /* We store a modified description.xml in the user's config dir */
        desc_path = g_build_filename (g_get_user_config_dir (),
                                      MODIFIED_DESC_DOC,
                                      NULL);

        /* Load description.xml. Loads the already-modified version, if it
         * exists. */
        if (g_file_test (desc_path, G_FILE_TEST_EXISTS))
                doc = xmlParseFile (desc_path);
        else
                doc = xmlParseFile (DATA_DIR
                                    G_DIR_SEPARATOR_S
                                    DESC_DOC);

        if (doc == NULL)
                return NULL;

        /* Modify description.xml to include a UDN and a friendy name */
        set_friendly_name_and_udn (doc);

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

                return NULL;
        }

        /* Set up GUPnP context */
        context = create_context (desc_path);
        if (!context) {
                g_free (desc_path);
                xmlFreeDoc (doc);

                return NULL;
        }

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

