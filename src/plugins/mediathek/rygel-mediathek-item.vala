using GLib;
using Rygel;
using Xml;

public errordomain ZdfMediathek.VideoItemError {
    XML_PARSE_ERROR
}

public class ZdfMediathek.VideoItem : Rygel.MediaItem {
    private VideoItem(MediaContainer parent, string title) {
        base(Checksum.compute_for_string(ChecksumType.MD5, title), parent, title, MediaItem.VIDEO_CLASS);
        this.mime_type = "video/x-ms-asf";
        this.author = "ZDF - Zweites Deutsches Fernsehen";
    }

    private static bool namespace_ok(Xml.Node* node) {
        return node->ns != null && node->ns->prefix == "media";
    }

    public static VideoItem create_from_xml(MediaContainer parent, Xml.Node *item) throws VideoItemError {
        string title = null;
        VideoItem video_item = null;
        AsxPlaylist asx = null;

        for (Xml.Node* item_child = item->children; item_child != null; item_child = item_child->next)
        {
            switch (item_child->name) {
                case "title":
                    title = item_child->get_content();
                    break;
                case "group":
                    if (namespace_ok(item_child)) {
                        for (Xml.Node* group = item_child->children; 
                             group != null;
                             group = group->next) {
                            if (group->name == "content") {
                                if (namespace_ok(group)) {
                                    Xml.Attr* attr = group->has_prop("url");
                                    if (attr != null) {
                                        var url = attr->children->content;
                                        if (url.has_suffix(".asx")) {
                                            debug("Found Url %s", url);
                                            asx = new AsxPlaylist(url);
                                            asx.parse();
                                        }
                                    }
                                    else {
                                        throw new VideoItemError.XML_PARSE_ERROR("group node has url property");
                                    }
                                }
                                else {
                                    throw new VideoItemError.XML_PARSE_ERROR("invalid or no namespace");
                                }
                            }
                        }
                    }
                    else {
                        throw new VideoItemError.XML_PARSE_ERROR("invalid or no namespace on group node");
                    }
                    break;
                default:
                    //debug("Got node->name %s", node->name);
                    break;
             }

        }
        if (title == null) {
            throw new VideoItemError.XML_PARSE_ERROR("Could not find title");
        }


        if (asx == null) {
            throw new VideoItemError.XML_PARSE_ERROR("Could not find uris");
        }

        video_item = new VideoItem(parent, title);
        foreach (string uri in asx.uris) {
            video_item.uris.add(uri);
        }

        return video_item;
    }
}
