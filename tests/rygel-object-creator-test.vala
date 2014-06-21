/*
 * Copyright (C) 2012 Nokia Corporation.
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

/* This is not used.
[CCode (cname = "uuid_generate", cheader_filename = "uuid/uuid.h")]
internal extern static void uuid_generate ([CCode (array_length = false)]
                                           uchar[] uuid);
[CCode (cname = "uuid_unparse", cheader_filename = "uuid/uuid.h")]
internal extern static void uuid_unparse ([CCode (array_length = false)]
                                          uchar[] uuid,
                                          [CCode (array_length = false)]
                                          uchar[] output);
*/

public const string DIDL_ITEM = """<?xml version="1.0" encoding="UTF-8"?>
<DIDL-Lite
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"
    xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/
        http://www.upnp.org/schemas/av/didl-lite-v2-20060531.xsd
      urn:schemas-upnp-org:metadata-1-0/upnp/
        http://www.upnp.org/schemas/av/upnp-v2-20060531.xsd">
    <item id="" parentID="0" restricted="0">
        <dc:title>New Song</dc:title>
        <upnp:class>object.item.audioItem</upnp:class>
        <res protocolInfo="*:*:*:*" />
    </item>
</DIDL-Lite>""";

public class Rygel.ServiceAction : GLib.Object {
    public int error_code;
    public string error_message;
    public string id;
    public string elements;

    public ServiceAction (string? container_id,
                          string? elements) {
        this.id = container_id;
        this.elements = elements;
    }

    public void @return() {}
    public void return_error (int code, string message) {
        this.error_code = code;
        this.error_message = message;
    }

    public new void @get (string arg1_name,
                          Type arg1_type,
                          out string arg1_val,
                          string arg2_name,
                          Type arg2_type,
                          out string arg2_val) {
        assert (arg1_name == "ContainerID");
        assert (arg1_type == typeof (string));
        arg1_val = id;

        assert (arg2_name == "Elements");
        assert (arg2_type == typeof (string));
        arg2_val = elements;
    }

    public new void @set (string arg1_name,
                          Type arg1_type,
                          string arg1_val,
                          string arg2_name,
                          Type arg2_type,
                          string arg2_val) {
        assert (arg1_name == "ObjectID");
        assert (arg1_type == typeof (string));

        assert (arg2_name == "Result");
        assert (arg2_type == typeof (string));
    }
}

public class Rygel.HTTPServer : GLib.Object {
}

public class Rygel.ObjectRemovalQueue : GLib.Object {
    public static ObjectRemovalQueue get_default () {
        return new ObjectRemovalQueue ();
    }

    public void queue (MediaObject object, Cancellable? cancellable) {
    }
}

public class Rygel.MediaServerPlugin : GLib.Object {
    public GLib.List<DLNAProfile> upload_profiles = new GLib.List<DLNAProfile>
        ();
}

public class Rygel.MediaObject : GLib.Object {
    public string id {get; set; }
    public string ref_id;
    public unowned MediaContainer parent { get; set; }
    public string upnp_class;
    public string title { get; set; }
    public GUPnP.OCMFlags ocm_flags;
    public Gee.ArrayList<string> uris;
    public uint object_update_id;

    public void add_uri (string uri) {
        this.uris.add (uri);
    }

    public Gee.ArrayList<string> get_uris () { return this.uris; }

    public string get_primary_uri () { return this.uris[0]; }

    internal void serialize (Rygel.Serializer serializer, HTTPServer server) {
    }

    public void apply_didl_lite (GUPnP.DIDLLiteObject object) {
    }

    public virtual async MediaObjects? get_children
                                            (uint         offset,
                                             uint         max_count,
                                             string       sort_criteria,
                                             Cancellable? cancellable)
                                            throws Error {
        return null;
    }

    public virtual async MediaObject? find_object (string       id,
                                                   Cancellable? cancellable)
                                                   throws Error {
        return null;
    }
}

public interface Rygel.TrackableContainer : Rygel.MediaContainer {
}

public interface Rygel.TrackableItem : Rygel.MediaItem {
}

public class Rygel.MediaItem : Rygel.MediaObject {
}

public class Rygel.MediaFileItem : Rygel.MediaItem {
    public string dlna_profile;
    public string mime_type;
    public long size;
    public bool place_holder;
    public string date;

    public MediaFileItem (string id, MediaContainer parent, string title) {
        this.id = id;
        this.parent = parent;
        this.title = title;
    }

}

public class Rygel.MusicItem : Rygel.AudioItem {
    public new const string UPNP_CLASS = "object.item.audioItem.musicTrack";

    public MusicItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}

public class Rygel.AudioItem : Rygel.MediaFileItem {
    public const string UPNP_CLASS = "object.item.audioItem";
    public string artist;
    public string album;

    public AudioItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}
public class Rygel.ImageItem : Rygel.MediaFileItem {
    public new const string UPNP_CLASS = "object.item.imageItem";
    public ImageItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}

public class Rygel.VideoItem : Rygel.MediaFileItem {
    public const string UPNP_CLASS = "object.item.videoItem";
    public VideoItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}

public class Rygel.PhotoItem : Rygel.MediaFileItem {
    public const string UPNP_CLASS = "object.item.imageItem.photo";
    public string creator;

    public PhotoItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}

public class Rygel.PlaylistItem : Rygel.MediaFileItem {
    public const string UPNP_CLASS = "object.item.playlistItem";

    public PlaylistItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}

public class Rygel.RootDevice : GLib.Object {
    public MediaServerPlugin resource_factory;

    public RootDevice () {
        this.resource_factory = new MediaServerPlugin ();
    }
}

public class Rygel.ContentDirectory : GLib.Object {
    public Cancellable cancellable;
    public MediaContainer root_container;
    public HTTPServer http_server;
    public RootDevice root_device;

    public ContentDirectory () {
        this.root_device = new RootDevice ();
    }
}

public class Rygel.MediaContainer : Rygel.MediaObject {
    public Gee.ArrayList<string> create_classes = new Gee.ArrayList<string> ();
    public int child_count { get; set; }
    public string sort_criteria = "+dc:title";
    public static const string ANY = "DLNA.ORG_AnyContainer";
    public static const string UPNP_CLASS = "object.container";
    public static const string STORAGE_FOLDER =
        "object.container.storageFolder";
    public static const string PLAYLIST =
        "object.container.playlistContainer";
    public uint update_id;

    // mockable elements
    public MediaObject found_object = null;

    public override async MediaObject? find_object (string       id,
                                           Cancellable? cancellable = null)
                                           throws Error {
        Idle.add (() => { find_object.callback (); return false; });
        yield;

        return found_object;
    }

    public signal void container_updated (MediaContainer container);
}

public class Rygel.MediaObjects : Gee.ArrayList<MediaObject> {
}

public class Rygel.WritableContainer : Rygel.MediaContainer {
    public bool can_create (string upnp_class) {
        return this.create_classes.contains (upnp_class);
    }

    public async File? get_writable (Cancellable? cancellable = null) {
        return File.new_for_commandline_arg ("/tmp");
    }

    public async void add_item (MediaItem    item,
                                Cancellable? cancellable = null) {
    }

    public async void add_container (MediaContainer container, Cancellable?
            cancellable = null) { }
}

public class Rygel.SearchableContainer : Rygel.MediaContainer {
    public MediaObjects result = new MediaObjects ();

    public async MediaObjects search (SearchExpression expression,
                                      int              offset,
                                      int              count,
                                      out int          total_matches,
                                      string           soer_criteria,
                                      Cancellable?     cancellable = null) {
        total_matches = 0;
        Idle.add (() => { search.callback (); return false; });
        yield;

        return result;
    }
}

public errordomain Rygel.ContentDirectoryError {
    BAD_METADATA,
    NO_SUCH_OBJECT,
    NO_SUCH_CONTAINER,
    INVALID_ARGS,
    RESTRICTED_PARENT,
    ERROR
}

public class Rygel.Transcoder {
}

public static void log_func (string? domain,
                             LogLevelFlags flags,
                             string message) {

    // Ignore critical of gee 0.6 and recent glib
    if (message.has_prefix ("Read-only property 'read-only-view' on class")) {
        Log.default_handler (domain, flags, message);

        return;
    }

    if (LogLevelFlags.LEVEL_CRITICAL in flags ||
        LogLevelFlags.LEVEL_ERROR in flags ||
        LogLevelFlags.FLAG_FATAL in flags) {
        print ("======> FAILED: %s: %s\n", domain ?? "", message);
        assert_not_reached ();
    }
}

public class Rygel.HTTPObjectCreatorTest : GLib.Object {

    public static int main (string[] args) {
        Log.set_default_handler (log_func);
        var test = new HTTPObjectCreatorTest ();
        test.test_parse_args ();
        test.test_didl_parsing ();
        test.test_fetch_container ();

        /* This is just here to avoid warnings about unused methods: */
        var serializer = new Serializer (SerializerType.GENERIC_DIDL);
        serializer.add_item ();
        serializer.add_container ();
        serializer.filter ("something");

        return 0;
    }

    // expected errors
    Error no_such_object;
    Error no_such_container;
    Error restricted_parent;
    Error bad_metadata;
    Error invalid_args;

    public HTTPObjectCreatorTest () {
        this.no_such_object = new ContentDirectoryError.NO_SUCH_OBJECT("");
        this.no_such_container = new ContentDirectoryError.NO_SUCH_CONTAINER("");
        this.restricted_parent = new ContentDirectoryError.RESTRICTED_PARENT("");
        this.bad_metadata = new ContentDirectoryError.BAD_METADATA("");
        this.invalid_args = new ContentDirectoryError.INVALID_ARGS("");
    }

    private void test_parse_args () {
        // check null container id
        var content_directory = new ContentDirectory ();

        var action = new ServiceAction (null, "");
        var creator = new ObjectCreator (content_directory, action);
        creator.run.begin ();
        assert (action.error_code == invalid_args.code);

        // check elements containing a comment
        action = new ServiceAction ("0", "<!-- This is an XML comment -->");
        creator = new ObjectCreator (content_directory, action);
        creator.run.begin ();
        assert (action.error_code == bad_metadata.code);

        // check null elements
        action = new ServiceAction ("0", null);
        creator = new ObjectCreator (content_directory, action);
        creator.run.begin ();
        assert (action.error_code == bad_metadata.code);
    }

    private void test_didl_parsing_step (Xml.Doc *doc, int expected_code) {
        string xml;

        doc->dump_memory_enc (out xml);
        var action = new ServiceAction ("0", xml);
        var content_directory = new ContentDirectory ();
        var creator = new ObjectCreator (content_directory, action);
        creator.run.begin ();
        assert (action.error_code == expected_code);
    }

    private void test_didl_parsing () {
        var xml = Xml.Parser.read_memory (DIDL_ITEM,
                                          DIDL_ITEM.length,
                                          null,
                                          null,
                                          Xml.ParserOption.RECOVER |
                                          Xml.ParserOption.NOBLANKS);
        var didl_node = xml->children;
        var item_node = didl_node->children;
        var content_directory = new ContentDirectory ();

        // test no DIDL
        var action = new ServiceAction ("0", "");
        var creator = new ObjectCreator (content_directory, action);
        creator.run.begin ();
        assert (action.error_code == bad_metadata.code);
        assert (action.error_message == "Bad metadata");

        // test empty DIDL
        item_node->unlink ();
        didl_node->set_content ("  ");
        this.test_didl_parsing_step (xml, bad_metadata.code);

        // test item node with missing restricted attribute
        var tmp = item_node->copy (1);
        tmp->unset_prop ("restricted");
        didl_node->add_child (tmp);
        this.test_didl_parsing_step (xml, bad_metadata.code);

        // test item node with restricted=1
        tmp->set_prop ("restricted", "1");
        this.test_didl_parsing_step (xml, bad_metadata.code);

        // test item node with invalid id
        tmp->unlink ();
        tmp = item_node->copy (1);
        tmp->set_prop ("id", "InvalidItemId");
        didl_node->add_child (tmp);
        this.test_didl_parsing_step (xml, bad_metadata.code);

        // test item node with missing id
        tmp->unset_prop ("id");
        this.test_didl_parsing_step (xml, bad_metadata.code);

        // test item node with missing title
        tmp->unlink ();
        tmp = item_node->copy (1);
        var title_node = tmp->children;
        title_node->unlink ();
        didl_node->add_child (tmp);
        this.test_didl_parsing_step (xml, bad_metadata.code);

        // test missing or empty upnp class
        tmp->unlink ();
        tmp = item_node->copy (1);
        var class_node = tmp->children->next;

        class_node->set_content ("");
        this.test_didl_parsing_step (xml, bad_metadata.code);

        class_node->unlink ();
        this.test_didl_parsing_step (xml, bad_metadata.code);
    }

    private void test_fetch_container_run (ObjectCreator creator) {
        var main_loop = new MainLoop (null, false);
        creator.run.begin ( () => { main_loop.quit (); });
        main_loop.run ();
    }

    private void test_fetch_container () {
        // check case when object is not found
        var content_directory = new ContentDirectory ();
        var root_container = new SearchableContainer ();
        content_directory.root_container = root_container;
        var action = new ServiceAction ("0", DIDL_ITEM);
        var creator = new ObjectCreator (content_directory, action);
        this.test_fetch_container_run (creator);
        assert (action.error_code == no_such_container.code);

        // check case when found object is not a container → Error 710
        // cf. ContentDirectory:2 spec, Table 2-22
        root_container.found_object = new MediaObject ();
        this.test_fetch_container_run (creator);
        assert (action.error_code == no_such_container.code);

        // check case when found container does not have OCMUpload set
        root_container.found_object = new MediaContainer ();
        this.test_fetch_container_run (creator);
        assert (action.error_code == restricted_parent.code);

        // check case when found container is not a writable container
        root_container.found_object.ocm_flags |= GUPnP.OCMFlags.UPLOAD;
        this.test_fetch_container_run (creator);
        assert (action.error_code == restricted_parent.code);

        // check when found container does not have the correct create class
        var container = new WritableContainer ();
        container.create_classes.add ("object.item.imageItem.musicTrack");
        container.ocm_flags |= GUPnP.OCMFlags.UPLOAD;
        root_container.found_object = container;
        this.test_fetch_container_run (creator);
        assert (action.error_code == bad_metadata.code);

        // check DLNA.ORG_AnyContainer when root container is not searchable
        content_directory.root_container = new MediaContainer ();
        action.id = "DLNA.ORG_AnyContainer";
        this.test_fetch_container_run (creator);
        assert (action.error_code == no_such_container.code);

        // check DLNA.ORG_AnyContainer when no writable container is found
        content_directory.root_container = new SearchableContainer ();
        this.test_fetch_container_run (creator);
        // We cannot distinguish this case from the "create-class doesn't match"
        // case
        assert (action.error_code == bad_metadata.code);
    }
}
