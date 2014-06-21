/*
 * Copyright (C) 2012 Intel Corporation
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

#include "example-root-container.h"

/**
 * Our derived MediaContainer.
 * In this example, we just derive from the SimpleContainer,
 * but a real-world server plugin might need something more sophisticated.
 */

enum  {
  RYGEL_EXAMPLE_ROOT_CONTAINER_DUMMY_PROPERTY
};

G_DEFINE_TYPE (RygelExampleRootContainer, rygel_example_root_container, RYGEL_TYPE_SIMPLE_CONTAINER)

RygelExampleRootContainer* rygel_example_root_container_new (const gchar *title);

static RygelExampleRootContainer*
rygel_example_root_container_construct (GType object_type, const gchar *title) {
  RygelExampleRootContainer *self;
  RygelMediaItem *item;

  g_return_val_if_fail (title != NULL, NULL);
  
  self = (RygelExampleRootContainer*) rygel_simple_container_construct_root (object_type, title);

  item = rygel_music_item_new ("test 1", (RygelMediaContainer*) self, "Test 1", RYGEL_MUSIC_ITEM_UPNP_CLASS);
  rygel_media_file_item_add_uri (item, "file:///home/murrayc/Music/Madness/05_Baggy_Trousers.mp3");
  rygel_media_file_item_set_mime_type (item, "audio/mpeg");
  rygel_simple_container_add_child_item ((RygelSimpleContainer*) self, item);
  g_object_unref (item);
  
  item = rygel_music_item_new ("test 2", (RygelMediaContainer*) self, "Test 1", RYGEL_MUSIC_ITEM_UPNP_CLASS);
  rygel_media_file_item_add_uri (item, "file:///home/murrayc/Music/08%20Busload%20of%20Faith.mp3");
  rygel_media_file_item_set_mime_type (item, "audio/mpeg");
  rygel_simple_container_add_child_item ((RygelSimpleContainer*) self, item);
  g_object_unref (item);

  return self;
}


RygelExampleRootContainer*
rygel_example_root_container_new (const gchar *title) {
  return rygel_example_root_container_construct (RYGEL_EXAMPLE_TYPE_ROOT_CONTAINER, title);
}


static void
rygel_example_root_container_class_init (RygelExampleRootContainerClass *klass) {
}


static void
rygel_example_root_container_init (RygelExampleRootContainer *self) {
}



