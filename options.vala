namespace Options {

    public string terminal_command;
    public string default_command;
    public bool pause_paste = true;

    void further_init() {
        if (terminal_command == null) {
            terminal_command = "/usr/bin/urxvt -pe -tabbed";
        }
        if (default_command == null) {
            // As for xterm.
            default_command = Environment.get_variable("SHELL");
            if (default_command == null) {
                Passwd.Passwd* pw = Passwd.getpwent();
                default_command = pw->pw_shell;
                if (default_command == null || default_command == "") {
                    default_command = "/bin/sh";
                }
            }
        }
    }

    public bool load_options() {
        further_init();

        bool success = true;

        try {
            var filename = make_config_filename();
            var keyfile = new KeyFile();
            keyfile.load_from_file(filename, KeyFileFlags.NONE);

            var group = "urxvtf";
            if (keyfile.has_group(group)) {
                if (keyfile.has_key(group, "terminal_command")) {
                    Options.terminal_command = keyfile.get_string(group,
                        "terminal_command");
                }
                if (keyfile.has_key(group, "default_command")) {
                    Options.default_command = keyfile.get_string(group,
                        "default_command");
                }
                if (keyfile.has_key(group, "pause_paste")) {
                    Options.pause_paste = keyfile.get_boolean(group,
                        "pause_paste");
                }
            }

            // XXX there seems to be a memory leak of keyfile here
        }
        catch (FileError e) {
            // Probably doesn't exist.
        }
        catch (KeyFileError e) {
            // Bad syntax.
            // XXX report the error
            stderr.printf("Error parsing configuration file.\n");
            success = false;
        }

        return success;
    }

    string make_config_filename() {
        var home_dir = Environment.get_home_dir();
        var filename = Path.build_filename(home_dir, ".urxvtfrc");
        return filename;
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
