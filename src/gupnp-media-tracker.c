/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
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
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

#include <string.h>
#include <libgupnp/gupnp.h>
#include <libgupnp-av/gupnp-av.h>
#include <dbus/dbus-glib.h>

#include "gupnp-media-tracker.h"

#define ROOT_DIR       "/"
#define ROOT_DIR_ALIAS "/media"

#define TRACKER_SERVICE "org.freedesktop.Tracker"
#define TRACKER_PATH "/org/freedesktop/tracker"

#define METADATA_IFACE "org.freedesktop.Tracker.Metadata"
#define FILES_IFACE "org.freedesktop.Tracker.Files"
#define TRACKER_IFACE "org.freedesktop.Tracker"

#define G_TYPE_PTR_ARRAY \
        (dbus_g_type_get_collection ("GPtrArray", G_TYPE_STRV))

G_DEFINE_TYPE (GUPnPMediaTracker,
               gupnp_media_tracker,
               G_TYPE_OBJECT);

struct _GUPnPMediaTrackerPrivate {
        char *root_id;

        GUPnPContext *context;

        DBusGProxy *metadata_proxy;
        DBusGProxy *files_proxy;
        DBusGProxy *tracker_proxy;

        GUPnPDIDLLiteWriter *didl_writer;
        GUPnPSearchCriteriaParser *search_parser;
};

enum {
        PROP_0,
        PROP_ROOT_ID,
        PROP_CONTEXT
};

static char *containers[] = {
        "Images",
        "Music",
        "Videos",
        NULL
};

/* GObject stuff */
static void
gupnp_media_tracker_dispose (GObject *object)
{
        GUPnPMediaTracker *tracker;
        GObjectClass *object_class;

        tracker = GUPNP_MEDIA_TRACKER (object);

        /* Free GUPnP resources */
        if (tracker->priv->context) {
                g_object_unref (tracker->priv->context);
                tracker->priv->context = NULL;
        }

        if (tracker->priv->search_parser) {
                g_object_unref (tracker->priv->search_parser);
                tracker->priv->search_parser = NULL;
        }

        if (tracker->priv->didl_writer) {
                g_object_unref (tracker->priv->didl_writer);
                tracker->priv->didl_writer = NULL;
        }

        if (tracker->priv->root_id) {
                g_free (tracker->priv->root_id);
                tracker->priv->root_id = NULL;
        }

        if (tracker->priv->metadata_proxy) {
                g_object_unref (tracker->priv->metadata_proxy);
                tracker->priv->metadata_proxy = NULL;
        }

        if (tracker->priv->files_proxy) {
                g_object_unref (tracker->priv->files_proxy);
                tracker->priv->files_proxy = NULL;
        }

        if (tracker->priv->tracker_proxy) {
                g_object_unref (tracker->priv->tracker_proxy);
                tracker->priv->tracker_proxy = NULL;
        }


        /* Call super */
        object_class = G_OBJECT_CLASS (gupnp_media_tracker_parent_class);
        object_class->dispose (object);
}

static void
gupnp_media_tracker_init (GUPnPMediaTracker *tracker)
{
         tracker->priv = G_TYPE_INSTANCE_GET_PRIVATE (tracker,
                                                     GUPNP_TYPE_MEDIA_TRACKER,
                                                     GUPnPMediaTrackerPrivate);

         /* Create a new DIDL-Lite writer */
        tracker->priv->didl_writer = gupnp_didl_lite_writer_new ();

        /* Create a new search criteria parser */
        tracker->priv->search_parser = gupnp_search_criteria_parser_new ();
}

static GObject *
gupnp_media_tracker_constructor (GType                  type,
                                 guint                  n_construct_params,
                                 GObjectConstructParam *construct_params)
{
        GObject *object;
        GObjectClass *object_class;
        GUPnPMediaTracker *tracker;
        DBusGConnection *connection;
        GError *error;

        object_class = G_OBJECT_CLASS (gupnp_media_tracker_parent_class);
        object = object_class->constructor (type,
                                            n_construct_params,
                                            construct_params);

        if (object == NULL)
                return NULL;

        tracker = GUPNP_MEDIA_TRACKER (object);

        /* Connect to session bus */
        error = NULL;
        connection = dbus_g_bus_get (DBUS_BUS_SESSION, &error);
        if (connection == NULL) {
                g_critical ("Failed to connect to tracker: %s\n",
                            error->message);

                g_error_free (error);

                goto error_case;
        }

        /* Create proxy to metadata interface of tracker object */
        tracker->priv->metadata_proxy =
                dbus_g_proxy_new_for_name (connection,
                                           TRACKER_SERVICE,
                                           TRACKER_PATH,
                                           METADATA_IFACE);

        /* A proxy to Files interface */
        tracker->priv->files_proxy =
                dbus_g_proxy_new_for_name (connection,
                                           TRACKER_SERVICE,
                                           TRACKER_PATH,
                                           FILES_IFACE);

        /* A proxy to Tracker interface */
        tracker->priv->tracker_proxy =
                dbus_g_proxy_new_for_name (connection,
                                           TRACKER_SERVICE,
                                           TRACKER_PATH,
                                           TRACKER_IFACE);


        if (tracker->priv->metadata_proxy == NULL ||
            tracker->priv->files_proxy == NULL ||
            tracker->priv->tracker_proxy == NULL) {
                g_critical ("Failed to create a proxy for '%s' object\n",
                            TRACKER_PATH);

                goto error_case;
        }

        /* Host the system root dir */
        gupnp_context_host_path (tracker->priv->context,
                                 ROOT_DIR,
                                 ROOT_DIR_ALIAS);

        return object;

error_case:
        g_object_unref (object);

        return NULL;
}

static void
gupnp_media_tracker_set_property (GObject      *object,
                                  guint         property_id,
                                  const GValue *value,
                                  GParamSpec   *pspec)
{
        GUPnPMediaTracker *tracker;

        tracker = GUPNP_MEDIA_TRACKER (object);

        switch (property_id) {
        case PROP_ROOT_ID:
                tracker->priv->root_id = g_value_dup_string (value);
                break;
        case PROP_CONTEXT:
                tracker->priv->context = g_value_dup_object (value);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
gupnp_media_tracker_get_property (GObject    *object,
                                  guint       property_id,
                                  GValue     *value,
                                  GParamSpec *pspec)
{
        GUPnPMediaTracker *tracker;

        tracker = GUPNP_MEDIA_TRACKER (object);

        switch (property_id) {
        case PROP_ROOT_ID:
                g_value_set_string (value, tracker->priv->root_id);
                break;
        case PROP_CONTEXT:
                g_value_set_object (value, tracker->priv->context);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
gupnp_media_tracker_class_init (GUPnPMediaTrackerClass *klass)
{
        GObjectClass *object_class;

        object_class = G_OBJECT_CLASS (klass);

        object_class->set_property = gupnp_media_tracker_set_property;
        object_class->get_property = gupnp_media_tracker_get_property;
        object_class->dispose = gupnp_media_tracker_dispose;
        object_class->constructor = gupnp_media_tracker_constructor;

        g_type_class_add_private (klass, sizeof (GUPnPMediaTrackerPrivate));

        /**
         * GUPnPMediaTracker:root-id
         *
         * ID of the root container.
         **/
        g_object_class_install_property
                (object_class,
                 PROP_ROOT_ID,
                 g_param_spec_string ("root-id",
                                      "RootID",
                                      "ID of the root container",
                                      NULL,
                                      G_PARAM_READWRITE |
                                      G_PARAM_CONSTRUCT_ONLY |
                                      G_PARAM_STATIC_NAME |
                                      G_PARAM_STATIC_NICK |
                                      G_PARAM_STATIC_BLURB));

        /**
         * GUPnPMediaTracker:context
         *
         * The GUPnP context to use.
         **/
        g_object_class_install_property
                (object_class,
                 PROP_CONTEXT,
                 g_param_spec_object ("context",
                                      "Context",
                                      "The GUPnP context to use",
                                      GUPNP_TYPE_CONTEXT,
                                      G_PARAM_READWRITE |
                                      G_PARAM_CONSTRUCT_ONLY |
                                      G_PARAM_STATIC_NAME |
                                      G_PARAM_STATIC_NICK |
                                      G_PARAM_STATIC_BLURB));
}

static void
add_container (const char          *id,
               const char          *parent_id,
               const char          *title,
               guint                child_count,
               GUPnPDIDLLiteWriter *didl_writer)
{
        gupnp_didl_lite_writer_start_container (didl_writer,
                                                id,
                                                parent_id,
                                                child_count,
                                                FALSE,
                                                FALSE);

        gupnp_didl_lite_writer_add_string
                        (didl_writer,
                         "class",
                         GUPNP_DIDL_LITE_WRITER_NAMESPACE_UPNP,
                         NULL,
                         "object.container.storageFolder");

        gupnp_didl_lite_writer_add_string (didl_writer,
                                           "title",
                                           GUPNP_DIDL_LITE_WRITER_NAMESPACE_DC,
                                           NULL,
                                           title);

        /* End of Container */
        gupnp_didl_lite_writer_end_container (didl_writer);
}

static void
add_root_container (const char          *root_id,
                    GUPnPDIDLLiteWriter *didl_writer)
{
        guint child_count;

        /* Count items */
        for (child_count = 0; containers[child_count]; child_count++);

        add_container (root_id,
                       "-1",
                       root_id,
                       child_count,
                       didl_writer);
}

static guint32
get_container_children_count (GUPnPMediaTracker *tracker,
                              const char        *container_id)
{
        GError *error;
        GPtrArray *array;
        guint32 count;
        guint i;

        array = NULL;
        error = NULL;
        if (!dbus_g_proxy_call (tracker->priv->tracker_proxy,
                                "GetStats",
                                &error,
                                G_TYPE_INVALID,
                                G_TYPE_PTR_ARRAY, &array,
                                G_TYPE_INVALID)) {
                g_critical ("error getting file list: %s", error->message);
                g_error_free (error);

                return 0;
        }

        count = 0;
        for (i = 0; i < array->len; i++) {
                char **stat;

                stat = g_ptr_array_index (array, i);

                if (strcmp (stat[0], container_id) == 0)
                        count = atoi (stat[1]);
        }

        g_ptr_array_free (array, TRUE);

        return count;
}

static char **
get_container_children_from_db (GUPnPMediaTracker *tracker,
                                const char        *container_id,
                                guint32            offset,
                                guint32            max_count,
                                guint32           *child_count)
{
        GError *error;
        char **result;

        *child_count = get_container_children_count (tracker, container_id);

        if (*child_count == 0)
                return NULL;

        result = NULL;
        error = NULL;
        if (!dbus_g_proxy_call (tracker->priv->files_proxy,
                                "GetByServiceType",
                                &error,
                                G_TYPE_INT, 0,
                                G_TYPE_STRING, container_id,
                                G_TYPE_INT, offset,
                                G_TYPE_INT, max_count,
                                G_TYPE_INVALID,
                                G_TYPE_STRV, &result,
                                G_TYPE_INVALID)) {
                g_critical ("error getting file list: %s", error->message);
                g_error_free (error);

                return NULL;
        }

        return result;
}

static gboolean
add_container_from_db (GUPnPMediaTracker   *tracker,
                       const char          *container_id,
                       const char          *parent_id)
{
        guint child_count;

        child_count = get_container_children_count (tracker, container_id);

        add_container (container_id,
                       parent_id,
                       container_id,
                       child_count,
                       tracker->priv->didl_writer);

        return TRUE;
}

static guint
add_root_container_children (GUPnPMediaTracker *tracker,
                             const char        *root_id)
{
        guint i;

        for (i = 0; containers[i]; i++) {
                add_container_from_db (tracker,
                                       containers[i],
                                       tracker->priv->root_id);
        }

        return i;
}

static void
add_item (GUPnPContext        *context,
          GUPnPDIDLLiteWriter *didl_writer,
          const char          *id,
          const char          *parent_id,
          const char          *mime,
          const char          *title,
          const char          *path)
{
        GUPnPDIDLLiteResource res;
        char *escaped_path;

        gupnp_didl_lite_writer_start_item (didl_writer,
                                           id,
                                           parent_id,
                                           NULL,
                                           FALSE);

        /* Add fields */
        gupnp_didl_lite_writer_add_string (didl_writer,
                                           "title",
                                           GUPNP_DIDL_LITE_WRITER_NAMESPACE_DC,
                                           NULL,
                                           title);

        gupnp_didl_lite_writer_add_string
                        (didl_writer,
                         "class",
                         GUPNP_DIDL_LITE_WRITER_NAMESPACE_UPNP,
                         NULL,
                         "object.item.audioItem.musicTrack");

        gupnp_didl_lite_writer_add_string
                        (didl_writer,
                         "album",
                         GUPNP_DIDL_LITE_WRITER_NAMESPACE_UPNP,
                         NULL,
                         "Some album");

        /* Add resource data */
        gupnp_didl_lite_resource_reset (&res);

        escaped_path = g_uri_escape_string (path,
                                            NULL,
                                            TRUE);
        /* URI */
        res.uri = g_strdup_printf ("http://%s:%d%s%s",
                                   gupnp_context_get_host_ip (context),
                                   gupnp_context_get_port (context),
                                   ROOT_DIR_ALIAS,
                                   escaped_path);
        g_free (escaped_path);

        /* Protocol info */
        res.protocol_info = g_strdup_printf ("http-get:*:%s:*", mime);

        gupnp_didl_lite_writer_add_res (didl_writer, &res);

        /* Cleanup */
        g_free (res.protocol_info);
        g_free (res.uri);

        /* End of item */
        gupnp_didl_lite_writer_end_item (didl_writer);
}

static gboolean
add_item_from_db (GUPnPMediaTracker *tracker,
                  const char        *category,
                  const char        *path,
                  const char        *parent_id)
{
        char *keys[] = {"File:Name",
                        "File:Mime",
                        NULL};
        char **values;
        gboolean success;
        GError *error;

        values = NULL;
        error = NULL;
        /* TODO: make this async */
        success = dbus_g_proxy_call (tracker->priv->metadata_proxy,
                                     "Get",
                                     &error,
                                     G_TYPE_STRING, category,
                                     G_TYPE_STRING, path,
                                     G_TYPE_STRV, keys,
                                     G_TYPE_INVALID,
                                     G_TYPE_STRV, &values,
                                     G_TYPE_INVALID);
        if (!success ||
            values == NULL ||
            values[0] == NULL ||
            values[1] == NULL) {
                g_critical ("failed to get metadata for %s.", path);

                if (error) {
                        g_critical ("Reason: %s\n", error->message);

                        g_error_free (error);
                }
        } else {
                add_item (tracker->priv->context,
                          tracker->priv->didl_writer,
                          path,
                          parent_id,
                          values[1],
                          values[0],
                          path);
        }

        return success;
}

static guint
add_container_children_from_db (GUPnPMediaTracker *tracker,
                                const char        *container_id,
                                guint32            offset,
                                guint32            max_count,
                                guint32           *child_count)
{
        guint i;
        char **children;

        children = get_container_children_from_db (tracker,
                                                   container_id,
                                                   offset,
                                                   max_count,
                                                   child_count);
        if (children == NULL)
                return 0;

        /* Iterate through all items */
        for (i = 0; children[i]; i++) {
                add_item_from_db (tracker,
                                  container_id,
                                  children[i],
                                  container_id);
        }

        g_strfreev (children);

        return i;
}

static char *
get_item_category (GUPnPMediaTracker *tracker,
                   const char        *uri)
{
        char *category;
        GError *error;
        gboolean success;

        category = NULL;
        error = NULL;
        success = dbus_g_proxy_call (tracker->priv->files_proxy,
                                     "GetServiceType",
                                     &error,
                                     G_TYPE_STRING, uri,
                                     G_TYPE_INVALID,
                                     G_TYPE_STRING, &category,
                                     G_TYPE_INVALID);
        if (!success || category == NULL) {
                g_critical ("failed to find service type for %s.", uri);

                if (error) {
                        g_critical ("Reason: %s\n", error->message);

                        g_error_free (error);
                }
        }

        return category;
}

GUPnPMediaTracker *
gupnp_media_tracker_new (const char   *root_id,
                         GUPnPContext *context)
{
        GUPnPResourceFactory *factory;

        factory = gupnp_resource_factory_get_default ();

        return g_object_new (GUPNP_TYPE_MEDIA_TRACKER,
                             "root-id", root_id,
                             "context", context,
                             NULL);
}

char *
gupnp_media_tracker_browse (GUPnPMediaTracker *tracker,
                            const char        *container_id,
                            const char        *filter,
                            guint32            starting_index,
                            guint32            requested_count,
                            const char        *sort_criteria,
                            guint32           *number_returned,
                            guint32           *total_matches,
                            guint32           *update_id)
{
        const char *didl;
        char *result;

        /* Start DIDL-Lite fragment */
        gupnp_didl_lite_writer_start_didl_lite (tracker->priv->didl_writer,
                                                NULL,
                                                NULL,
                                                TRUE);

        if (strcmp (container_id, tracker->priv->root_id) == 0) {
                *number_returned =
                        add_root_container_children (tracker,
                                                     tracker->priv->root_id);
                *total_matches = *number_returned;
        } else {
                *number_returned =
                        add_container_children_from_db (tracker,
                                                        container_id,
                                                        starting_index,
                                                        requested_count,
                                                        total_matches);
        }

        if (*number_returned > 0) {
                /* End DIDL-Lite fragment */
                gupnp_didl_lite_writer_end_didl_lite
                                (tracker->priv->didl_writer);

                /* Retrieve generated string */
                didl = gupnp_didl_lite_writer_get_string
                                (tracker->priv->didl_writer);
                result = g_strdup (didl);

                *update_id = GUPNP_INVALID_UPDATE_ID;
        } else
                result = NULL;

        /* Reset the parser state */
        gupnp_didl_lite_writer_reset (tracker->priv->didl_writer);

        return result;
}

char *
gupnp_media_tracker_get_metadata (GUPnPMediaTracker *tracker,
                                  const char        *object_id,
                                  const char        *filter,
                                  const char        *sort_criteria,
                                  guint32           *update_id)
{
        char *result;
        guint i;
        gboolean found;

        /* Start DIDL-Lite fragment */
        gupnp_didl_lite_writer_start_didl_lite (tracker->priv->didl_writer,
                                                NULL,
                                                NULL,
                                                TRUE);
        found = FALSE;
        if (strcmp (object_id, tracker->priv->root_id) == 0) {
                        add_root_container (tracker->priv->root_id,
                                            tracker->priv->didl_writer);

                        found = TRUE;
        } else {
                /* First try the containers */
                for (i = 0; containers[i]; i++) {
                        if (strcmp (object_id, containers[i]) == 0) {
                                add_container_from_db (tracker,
                                                       containers[i],
                                                       tracker->priv->root_id);

                                found = TRUE;

                                break;
                        }
                }

                if (!found) {
                        /* Now try items */
                        char *category;

                        category = get_item_category (tracker, object_id);

                        if (category != NULL) {
                                found = add_item_from_db (tracker,
                                                          category,
                                                          object_id,
                                                          category);

                                g_free (category);
                        }
                }
        }

        if (found) {
                const char *didl;

                /* End DIDL-Lite fragment */
                gupnp_didl_lite_writer_end_didl_lite
                                        (tracker->priv->didl_writer);

                /* Retrieve generated string */
                didl = gupnp_didl_lite_writer_get_string
                                        (tracker->priv->didl_writer);
                result = g_strdup (didl);
        } else
                result = NULL;

        /* Reset the parser state */
        gupnp_didl_lite_writer_reset (tracker->priv->didl_writer);

        *update_id = GUPNP_INVALID_UPDATE_ID;

        return result;
}

