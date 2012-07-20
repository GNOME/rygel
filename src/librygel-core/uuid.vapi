[CCode (cheader_filename = "uuid/uuid.h")]
namespace UUID {
    public static void generate ([CCode (array_length = false)] uchar[] uuid);
    public static void unparse ([CCode (array_length = false)] uchar[] uuid,
                                [CCode (array_length = false)] uchar[] output);

}
