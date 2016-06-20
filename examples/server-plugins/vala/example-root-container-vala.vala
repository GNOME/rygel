/*
 * Copyright (C) 2012 Intel Corporation
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * Our derived MediaContainer.
 * In this example, we just derive from the SimpleContainer,
 * but a real-world server plugin might need something more sophisticated.
 */
public class Rygel.Example.RootContainerVala : Rygel.SimpleContainer {
    public RootContainerVala (string title) {
        base.root (title);

        /*
         * Add media items to be served from this container via UPnP,
         * using the standard AudioItem, ImageItem, MusicItem and 
         * VideoItem classes, with URIs.
         * A real server plugin would probably want to populate the container
         * dynamically, for instance by monitoring a directory on the file system.
         *
         * Plugins may alternatively derive their own item classes, overriding 
         * create_stream_source(). For instance, this could allow the plugin
         * to server content from a database rather than from the file system.
         */
        var item = new MusicItem ("test 1", this, "Test 1");
        item.add_uri ("file:///home/murrayc/Music/Madness/05_Baggy_Trousers.mp3");
        item.mime_type = "audio/mpeg";
        item.add_engine_resources.begin ();
        this.add_child_item(item);

        item = new MusicItem ("test 2", this, "Test 2");
        item.add_uri ("file:///home/murrayc/Music/08%20Busload%20of%20Faith.mp3");
        item.mime_type = "audio/mpeg";
        item.add_engine_resources.begin ();
        this.add_child_item(item);
    }
}


