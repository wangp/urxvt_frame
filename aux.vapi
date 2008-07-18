// Bindings to C functions that Vala lacks.

namespace Passwd {
    [CCode (cname = "struct passwd", cheader_filename = "pwd.h")]
    public struct Passwd {
        public string pw_name;
        public string pw_passwd;
        public int    pw_uid;
        public int    pw_gid;
        public string pw_gecos;
        public string pw_dir;
        public string pw_shell;
    }

    [CCode (cname="getpwent")]
    public static Passwd* getpwent ();
}

// vim: ft=cs ts=8 sts=4 sw=4 et
