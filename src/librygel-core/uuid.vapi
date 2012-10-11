[CCode (cheader_filename = "uuid/uuid.h")]
namespace UUID {
    public static void generate ([CCode (array_length = false)] uchar[] uuid);
    public static void unparse ([CCode (array_length = false)] uchar[] uuid,
                                [CCode (array_length = false)] uchar[] output);

    public static string get () {
        var id = new uchar[16];
        var unparsed = new uchar[51];

        UUID.generate (id);
        UUID.unparse (id, unparsed);
        unparsed[50] = '\0';

        return (string) unparsed;
    }
}
