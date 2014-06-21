/*
 * Copyright (C) 2012 Openismus GmbH.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/*
 * Demo application for librygel-server.
 *
 * Creates a stand-alone UPnP server that exposes the contents of the current
 * folder or the folder passed as argument.
 *
 * Usage:
 *   standalone-server [<folder>]
 *
 * The server listens on wlan0 and eth0 by default.
 */

#include <gio/gio.h>
#include <rygel-server.h>
#include <rygel-core.h>

int main (int argc, char *argv[])
{
    RygelMediaServer *server;
    RygelSimpleContainer *root_container;
    char *path;
    GFile *source_dir;
    GFileEnumerator *enumerator;
    GFileInfo *info;
    int i;
    GMainLoop *loop;
    GError *error = NULL;

    g_type_init ();

    rygel_media_engine_init (&error);

    if (error != NULL) {
        g_print ("Could not initialize media engine: %s\n",
                 error->message);
        g_error_free (error);

        return EXIT_FAILURE;
    }

    g_set_application_name ("Standalone-Server");

    root_container = rygel_simple_container_new_root ("Sample implementation");
    if (argc >= 2) {
        path = g_strdup (argv[1]);
    } else {
        path = g_get_current_dir ();
    }

    source_dir = g_file_new_for_commandline_arg (path);
    g_free (path);

    enumerator = g_file_enumerate_children (source_dir,
                                            G_FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME ","
                                            G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE,
                                            G_FILE_QUERY_INFO_NONE,
                                            NULL,
                                            NULL);
    info = g_file_enumerator_next_file (enumerator, NULL, NULL);
    i = 0;
    while (info != NULL) {
        GFile *file;
        const char *display_name, *content_type;
        char *uri, *id;
        RygelMediaItem *item = NULL;
        GError *error = NULL;

        display_name = g_file_info_get_display_name (info);
        content_type = g_file_info_get_content_type (info);
        file = g_file_get_child_for_display_name (source_dir, display_name, &error);
        if (error != NULL) {
            g_critical ("Failed to get child: %s", error->message);

            return 127;
        }
        uri = g_file_get_uri (file);
        g_object_unref (file);
        id = g_strdup_printf ("%06d", i);

        if (g_str_has_prefix (content_type, "audio/")) {
            item = rygel_audio_item_new (id,
                                         root_container,
                                         display_name,
                                         RYGEL_AUDIO_ITEM_UPNP_CLASS);
        } else if (g_str_has_prefix (content_type, "video/")) {
            item = rygel_video_item_new (id,
                                         root_container,
                                         display_name,
                                         RYGEL_VIDEO_ITEM_UPNP_CLASS);
        } else if (g_str_has_prefix (content_type, "image/")) {
            item = rygel_image_item_new (id,
                                         root_container,
                                         display_name,
                                         RYGEL_IMAGE_ITEM_UPNP_CLASS);
        }
        g_free (id);

        if (item != NULL) {
            GeeArrayList* uris;

            rygel_media_file_item_set_mime_type (RYGEL_MEDIA_FILE_ITEM (item),
                                                 content_type);

            rygel_media_object_add_uri (RYGEL_MEDIA_OBJECT (item), uri);

            rygel_simple_container_add_child_item (root_container, item);
        }

        i++;
        info = g_file_enumerator_next_file (enumerator, NULL, NULL);
    }

    server = rygel_media_server_new ("LibRygel sample server",
                                     root_container,
                                     RYGEL_PLUGIN_CAPABILITIES_NONE);
    rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (server), "eth0");
    rygel_media_device_add_interface (RYGEL_MEDIA_DEVICE (server), "wlan0");

    loop = g_main_loop_new (NULL, FALSE);
    g_main_loop_run (loop);
}
