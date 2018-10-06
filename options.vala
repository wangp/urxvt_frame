// Probably better as a class.
namespace Options {

    public string[] terminal_command;

    public string[] default_command;

    private string[] _first_command;
    public static string[] first_command() {
        if (_first_command != null) {
            return _first_command;
        } else {
            return default_command;
        }
    }

    public bool pause_paste = false;

    void further_init() {
        if (terminal_command == null) {
            terminal_command = {"/usr/bin/urxvt", "-pe", "-tabbed"};
        }
        if (default_command == null) {
            // As for xterm.
            string cmd = Environment.get_variable("SHELL");
            if (cmd == null) {
                Posix.Passwd* pw = Posix.getpwent();
                cmd = pw->pw_shell;
                if (cmd == null || cmd == "") {
                    cmd = "/bin/sh";
                }
            }
            Options.default_command = {cmd};
        }
    }

    public bool load_options() {
        further_init();

        bool success = true;

        try {
            var filename = make_config_filename();
            var keyfile = new KeyFile();
            keyfile.load_from_file(filename, KeyFileFlags.NONE);

            var group = "urxvt_frame";
            if (keyfile.has_group(group)) {
                if (keyfile.has_key(group, "terminal_command")) {
                    var v = keyfile.get_string(group, "terminal_command");
                    // Might want sh-style word splitting.
                    Options.terminal_command = v.split(" ");
                }
                if (keyfile.has_key(group, "default_command")) {
                    var v = keyfile.get_string(group, "default_command");
                    // Might want sh-style word splitting.
                    Options.default_command = v.split(" ");
                }
                if (keyfile.has_key(group, "pause_paste")) {
                    Options.pause_paste =
                        keyfile.get_boolean(group, "pause_paste");
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
        var filename = Path.build_filename(home_dir,
            ".config/urxvt_frame/urxvt_frame.conf");
        return filename;
    }

    public void parse_command_line_options(string[] argv)
        throws OptionError
    {
        // We don't accept any command line arguments other than -e
        // at the moment.
        for (int i = 1; i < argv.length; i++) {
            if (argv[i] == "-e") {
                if (i == argv.length - 1) {
                    throw new OptionError.BAD_VALUE(
                        "option '-e' requires an argument");
                }

                Options._first_command = { argv[i + 1] };
                for (int j = i + 2; j < argv.length; j++) {
                    Options._first_command += argv[j];
                }

                return;
            }
        }
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
