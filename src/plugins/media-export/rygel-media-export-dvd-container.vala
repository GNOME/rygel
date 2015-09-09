/*
 * Copyright (C) 2015 Jens Georg <mail@jensge.org>.
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
using Gee;

internal class Rygel.MediaExport.DVDContainer : MediaContainer, UpdatableObject {
    public new const string UPNP_CLASS = MediaContainer.PLAYLIST + ".DVD";
    public const string PREFIX = "dvd";
    public const string TRACK_PREFIX = "dvd-track";

    public string path { get; construct set; }

    private GUPnP.XMLDoc doc;

    public DVDContainer (string          id,
                         MediaContainer? parent,
                         string          title,
                         string          path) {
        Object (id : id,
                upnp_class : DVDContainer.UPNP_CLASS,
                title : title,
                parent : parent,
                child_count : 0,
                path : path);
    }

    public override void constructed () {
        base.constructed ();

        var cache_path = this.get_cache_path (this.path);
        var doc = Xml.Parser.read_file (cache_path,
                                        null,
                                        Xml.ParserOption.NOERROR |
                                        Xml.ParserOption.NOWARNING);
        this.doc = new GUPnP.XMLDoc (doc);
        var it = doc->get_root_element ()->children;
        var child_count = 0;

        while (it != null) {
            if (it->name == "title") {
                this.title = it->children->content;
            } else if (it->name == "track") {
                child_count++;
            }

            it = it->next;
        }

        this.child_count = child_count;
    }

    public override async MediaObjects? get_children (
                                                     uint         offset,
                                                     uint         max_count,
                                                     string       sort_criteria,
                                                     Cancellable? cancellable)
                                                     throws Error {
        var children = new MediaObjects ();

        var context = new Xml.XPath.Context (this.doc.doc);
        var xpo = context.eval ("/lsdvd/track");
        if (xpo->type != Xml.XPath.ObjectType.NODESET) {
            delete xpo;
            warning ("No tracks found in DVD");

            return children;
        }

        for (int i = 0; i < xpo->nodesetval->length (); i++) {
            var node = xpo->nodesetval->item (i);
            var item = this.get_item_for_xml (i, node);
            children.add (item);
        }

        delete xpo;

        return children;
    }

    public override async MediaObject? find_object (string id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        if (!id.has_prefix (DVDContainer.TRACK_PREFIX)) {
            return null;
        }

        var parts = id.split (":");
        var track = int.parse (parts[2]);
        var context = new Xml.XPath.Context (this.doc.doc);
        var xpo = context.eval ("/lsdvd/track");
        if (!(xpo->type == Xml.XPath.ObjectType.NODESET &&
              xpo->nodesetval->length () >= track)) {
            delete xpo;

            warning ("No track %s in DVD", parts[2]);

            return null;
        }

        var object = this.get_item_for_xml (int.parse (parts[2]),
                                            xpo->nodesetval->item (track));
        delete xpo;

        return object;
    }

    private string get_cache_path (string image_path) {
        unowned string user_cache = Environment.get_user_cache_dir ();
        var id = Checksum.compute_for_string (ChecksumType.MD5, image_path);
        var cache_folder = Path.build_filename (user_cache,
                                                "rygel",
                                                "dvd-content");
        DirUtils.create_with_parents (cache_folder, 0700);
        return Path.build_filename (cache_folder, id);
    }

    public async void commit () throws Error {
        yield this.commit_custom (true);
    }

    public async void commit_custom (bool override_guarded) throws Error {
        MediaCache.get_default ().save_container (this);
    }

    private string get_track_id (int track) {
        var parts = this.id.split (":");

        parts[0] = "dvd-track";
        parts += track.to_string ();

        return string.joinv (":", parts);
    }

    private MediaFileItem get_item_for_xml (int track, Xml.Node *node) {
        var item = new VideoItem (this.get_track_id (track),
                                  this,
                                  "Track %d".printf (track + 1));
        item.parent_ref = this;

        var uri = new Soup.URI (this.get_uris ()[0]);
        uri.set_scheme ("dvd");
        uri.set_query ("title=%d".printf (track + 1));
        item.add_uri (uri.to_string (false));
                var media_engine = MediaEngine.get_default ( );
                media_engine.get_resources_for_item.begin ( item,
                                                            (obj, res) => {
                    var added_resources = media_engine
                                          .get_resources_for_item.end (res);
                    debug ("Adding %d resources to item source %s",
                           added_resources.size, item.get_primary_uri ());
                    foreach (var resrc in added_resources) {
                       debug ("Media-export item media resource %s",
                              resrc.get_name ());
                    }
                    item.get_resource_list ().add_all (added_resources);
                  });

        return item;
    }
}
