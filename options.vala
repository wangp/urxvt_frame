namespace Options {

    public string command;
    public bool pause_paste = true;

    void further_init() {
        if (command == null) {
            command = "/usr/bin/urxvt -pe -tabbed";
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
                if (keyfile.has_key(group, "command")) {
                    Options.command = keyfile.get_string(group, "command");
                }
                if (keyfile.has_key(group, "pause_paste")) {
                    Options.pause_paste = keyfile.get_boolean(group,
                        "pause_paste");
                }
            }
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
