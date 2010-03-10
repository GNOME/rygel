public errordomain Rygel.HTTPRequestError {
    UNACCEPTABLE = Soup.KnownStatusCode.NOT_ACCEPTABLE,
    BAD_REQUEST = Soup.KnownStatusCode.BAD_REQUEST,
    NOT_FOUND = Soup.KnownStatusCode.NOT_FOUND
}

public errordomain Rygel.TestError {
    SKIP
}

public class Rygel.HTTPServer : GLib.Object {
    private const string SERVER_PATH = "/RygelHTTPServer/Rygel/Test";

    public string path_root { get; private set; }

    public GUPnP.Context context;

    public HTTPServer () throws TestError {
        this.path_root = SERVER_PATH;

        try {
            this.context = new GUPnP.Context (null, "lo", 0);
        } catch (Error error) {
            throw new TestError.SKIP ("Network context not available");
        }

        assert (this.context != null);
        assert (this.context.host_ip != null);
        assert (this.context.port > 0);
    }
}

public class Rygel.HTTPItemURITest : GLib.Object {
    private const string ITEM_ID = "HELLO";
    private const int THUMBNAIL_INDEX = 1;
    private const string TRANSCODE_TARGET = "MP3";

    private HTTPServer server;

    public static int main (string[] args) {
        try {
            var test = new HTTPItemURITest ();

            test.run ();
        } catch (TestError error) {
            // FIXME: We should catch the exact error but currently valac issues
            // unreachable warning if we do so.
            return 77;
        } catch (Error error) {
            critical ("%s", error.message);

            return -1;
        }

        return 0;
    }

    public void run () throws Error {
        var uris = new HTTPItemURI[] {
            this.test_construction (),
            this.test_construction_with_thumbnail (),
            this.test_construction_with_transcoder () };

        foreach (var uri in uris) {
            var str = this.test_to_string (uri);
            this.test_construction_from_string (str);
        }
    }

    private HTTPItemURITest () throws TestError {
        this.server = new HTTPServer ();
    }

    private HTTPItemURI test_construction () {
        var uri = new HTTPItemURI (ITEM_ID, this.server);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_with_thumbnail () {
        var uri = new HTTPItemURI (ITEM_ID,
                                   this.server,
                                   THUMBNAIL_INDEX);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_with_transcoder () {
        var uri = new HTTPItemURI (ITEM_ID,
                                   this.server,
                                   THUMBNAIL_INDEX,
                                   TRANSCODE_TARGET);
        assert (uri != null);

        return uri;
    }

    private HTTPItemURI test_construction_from_string (string str)
                                                       throws Error {
        var uri = new HTTPItemURI.from_string (str, this.server);
        assert (uri != null);
        assert (uri.to_string () == str);

        return uri;
    }

    private string test_to_string (HTTPItemURI uri) {
        var str = uri.to_string ();
        assert (str != null);

        return str;
    }
}
