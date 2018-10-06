class Options {

    public string[] terminal_command {
        get;
        private set;
        default = {"/usr/bin/urxvt", "-pe", "-tabbed"};
    }

    public string[] default_command {
        get;
        private set;
        default = {"/bin/sh"};
    }

    string[]? _first_command;
    public string[] first_command {
        get {
            return (_first_command != null) ? _first_command : default_command;
        }
    }

    public bool pause_paste {
        get;
        private set;
        default = false;
    }

    public Options() {
        string? shell = Environment.get_variable("SHELL");
        if (shell == null) {
            Posix.Passwd* pw = Posix.getpwuid(Posix.getuid());
            if (pw != null) {
                shell = pw->pw_shell;
            }
        }
        if (shell != null && shell != "") {
            default_command = {(!) shell};
        }
    }

    public void load_options()
        throws KeyFileError
    {
        var filename = make_config_filename();
        var keyfile = new KeyFile();
        try {
            keyfile.load_from_file(filename, KeyFileFlags.NONE);
        }
        catch (FileError e) {
            // Probably doesn't exist.
            return;
        }

        var group = "urxvt_frame";
        if (keyfile.has_key(group, "terminal_command")) {
            var v = keyfile.get_string(group, "terminal_command");
            // Might want sh-style word splitting.
            terminal_command = v.split(" ");
        }
        if (keyfile.has_key(group, "default_command")) {
            var v = keyfile.get_string(group, "default_command");
            // Might want sh-style word splitting.
            default_command = v.split(" ");
        }
        if (keyfile.has_key(group, "pause_paste")) {
            pause_paste = keyfile.get_boolean(group, "pause_paste");
        }
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
                _first_command = argv[i + 1 : argv.length];
                return;
            }
        }
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
