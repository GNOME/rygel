/*
 * Copyright (C) 2008-2009 Jens Georg <mail@jensge.org>.
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

using Rygel;
using GUPnP;
using Gee;
using GLib;

/**
 * Simple plugin which exposes the media contents of a directory via UPnP.
 * 
 * This plugin is currently meant for testing purposes only. It has several 
 * drawbacks like:
 *
 * * No sorting
 * * flat hierarchy
 * * no metadata extraction apart from content type
 * * no monitoring
 */
[ModuleInit]
public Plugin load_plugin() {
    Plugin plugin = new Plugin("Folder");

    var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                          ContentDirectory.UPNP_TYPE,
                                          ContentDirectory.DESCRIPTION_PATH,
                                          typeof (Folder.FolderContentDir));

    plugin.add_resource (resource_info);

    return plugin;
}

public class Folder.FolderContentDir : ContentDirectory {

    // FIXME get some configuration for this
    public static const string DIR = "/home/jens/Media";

    public override MediaContainer? create_root_container () {
        return new FolderRootContainer (DIR);
    }
}

/**
 * Very simple media item. 
 */
public class Folder.FilesystemMediaItem : Rygel.MediaItem {
    public FilesystemMediaItem(MediaContainer parent, 
                               File file, 
                               FileInfo file_info) {
        string item_class;
        var content_type = file_info.get_content_type();

        if (content_type.has_prefix("video/")) {
            item_class = MediaItem.VIDEO_CLASS;
        }
        else if (content_type.has_prefix("audio/")) {
            item_class = MediaItem.AUDIO_CLASS;
        }
        else if (content_type.has_prefix("image/")) {
            item_class = MediaItem.IMAGE_CLASS;
        }
        else {
            return;
        }

        base(Checksum.compute_for_string(ChecksumType.MD5, file_info.get_name()), 
             parent,
             file_info.get_name(),
             item_class);

        this.mime_type = content_type;
        this.uris.add(GLib.Markup.escape_text(file.get_uri()));
    }
}
