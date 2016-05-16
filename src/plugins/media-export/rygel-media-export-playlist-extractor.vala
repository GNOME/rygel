using GUPnP;

internal class Rygel.MediaExport.PlaylistExtractor : Extractor {
    public PlaylistExtractor (File file) {
        GLib.Object (file: file);
    }

    public override async void run () throws Error {
        yield base.run ();

        uint8[] contents;

        if (!yield file.load_contents_async (null, out contents, null)) {
            throw new ExtractorError.INVALID ("Failed to read file");
        }

        /* Do some heuristic check if this file looks like XML */
        var i = 0;
        while (((char) contents[i]).isspace () && i < contents.length) {
            i++;
        }

        if (contents[i] != '<') {
            throw new ExtractorError.INVALID ("Not an XML file");
        }

        var didl_s = new MediaCollection.from_string ((string) contents);
        var author = didl_s.author;
        var title = didl_s.title;

        if (author == null &&
            title == null &&
            didl_s.get_items () == null) {
            throw new ExtractorError.INVALID ("Not a DIDL-Lite playlist");
        }

        if (title != null) {
            this.serialized_info.insert (Serializer.TITLE, "s", title);
        }

        if (author != null) {
            this.serialized_info.insert (Serializer.ARTIST, "s", author);
        }

        this.serialized_info.insert (Serializer.DLNA_PROFILE, "s", "DIDL_S");
        this.serialized_info.insert (Serializer.UPNP_CLASS,
                                     "s",
                                     UPNP_CLASS_PLAYLIST);
    }
}
