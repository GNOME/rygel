namespace Rygel.EnergyManagementHelper {
    /* Workaround for https://bugzilla.gnome.org/show_bug.cgi?id=707180 */
    [CCode (cname = "struct sockaddr", cheader_filename = "sys/socket.h", destroy_function = "")]
    public struct SockAddr {
        public int sa_family;
        [CCode (array_length = false)]
        public char[] sa_data;
    }
}
