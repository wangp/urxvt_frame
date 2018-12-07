using GLib;
using Gtk;

int main(string[] argv) {
    Options options = new Options();
    try {
        options.load_options();
        options.parse_command_line_options(argv);
    }
    catch (KeyFileError e) {
        stdout.printf("%s\n", e.message);
        return 1;
    }
    catch (ShellError e) {
        stdout.printf("%s\n", e.message);
        return 1;
    }
    catch (OptionError e) {
        stdout.printf("%s\n", e.message);
        return 1;
    }

    Gtk.init(ref argv);
    new UWindow(options, null);
    Gtk.main();
    return 0;
}

class UWindow : Gtk.Window {

    static List<UWindow> all_windows;

    public UWindow(Options options, string? initial_directory) {
        all_windows.append(this);

        this.title = "urxvt-frame";
        this.set_default_size(700, 400);
        this.destroy.connect(this.on_destroy);

        try {
            var theme = IconTheme.get_default();
            var icon = theme.load_icon("utilities-terminal", 48, 0);
            if (icon != null) {
                this.icon = (!) icon;
            }
        } catch (Error e) {
            // stderr.printf("Could not load application icon: %s\n", e.message);
        }

        var notebook = new UNotebook(options, initial_directory);
        this.add(notebook);
        this.show_all();
    }

    void on_destroy() {
        all_windows.remove(this);
        if (all_windows.length() == 0) {
            Gtk.main_quit();
        }
    }
}

class UNotebook : Gtk.Notebook {

    int counter = 0;

    public UNotebook(Options options, string? initial_directory) {
        this.flags &= ~WidgetFlags.CAN_FOCUS;
        this.scrollable = true;
        this.page_removed.connect(this.on_page_removed);

        this.new_terminal(options, initial_directory);
    }

    void on_page_removed(Gtk.Widget child, uint page_num) {
        if (this.get_n_pages() == 0) {
            // p can be null if the whole window is closed.
            var p = this.get_parent();
            if (p != null) {
                ((!) p).destroy();
            }
        }
    }

    public void new_terminal(Options options, string? initial_directory) {
        var n = this.counter++;
        var first_terminal = (n == 0);
        var rxvt = new URxvt(options, initial_directory, first_terminal);
        var label = new Gtk.Label("rxvt-%d".printf(n));
        var page = this.append_page(rxvt, label);
        this.set_tab_reorderable(rxvt, true);
        rxvt.show_all();
        this.set_current_page(page);
    }

    public void previous_page() {
        var page = this.get_current_page() - 1;
        if (page < 0) {
            page = this.get_n_pages() - 1;
        }
        this.set_current_page(page);
    }

    public void do_next_page() {
        var n = this.get_n_pages();
        var page = this.get_current_page() + 1;
        if (page >= n) {
            page = 0;
        }
        this.set_current_page(page);
    }

    public void do_select_page(int n) {
        this.set_current_page(n);
    }

    public void reorder_page(Gtk.Widget child, int delta) {
        var page = this.get_current_page() + delta;
        if (page >= 0 && page < this.get_n_pages()) {
            this.reorder_child(child, page);
        }
    }
}

class URxvt : Gtk.Socket {

    Options options;
    string? initial_directory;
    bool first_terminal;
    Pid terminal_pid;
    string? shell_pid;  // child of terminal_pid

    public URxvt(Options options, string? initial_directory, bool first_terminal) {
        this.options = options;
        this.initial_directory = initial_directory;
        this.first_terminal = first_terminal;

        this.flags |= WidgetFlags.CAN_FOCUS;
        this.border_width = 0;

        // Reduce the initial flicker when the terminal starts up.  Of course,
        // this assumes the terminal background colour is black.
        Gdk.Color black = { 0, 0, 0, 0 };
        this.modify_bg(Gtk.StateType.NORMAL, black);

        this.realize.connect(on_realize);
        this.plug_added.connect(on_plug_added);
        this.map_event.connect(on_map_event);
        this.key_press_event.connect(on_key_press_event);
    }

    UNotebook? parent_notebook {
        get {
            return this.get_parent() as UNotebook;
        }
    }

    void on_realize() {
        Gdk.NativeWindow id = this.get_id();

        string[] argv = options.terminal_command;
        argv += "-embed";
        argv += "0x%lx".printf((ulong) id);
        argv += "-e";
        if (this.first_terminal) {
            foreach (var arg in options.first_command) {
                argv += arg;
            }
        } else {
            foreach (var arg in options.default_command) {
                argv += arg;
            }
        }

        try {
            Process.spawn_async(initial_directory, argv, null,
                SpawnFlags.SEARCH_PATH, null, out terminal_pid);
        }
        catch (SpawnError e) {
            stderr.printf("Error running `%s': %s\n",
                string.joinv(" ", (string?[]) argv), e.message);
        }
    }

    void on_plug_added() {
    }

    bool on_map_event() {
        // Will be called when the tab is switched-to.
        this.grab_focus();
        return false;
    }

    // Hack. I don't know if this is portable.
    // Update: doesn't seem so.
    // const ushort Hw_Insert = 0x6a;
    const ushort Hw_Insert = 0x76;

    bool on_key_press_event(Gdk.EventKey evt) {
        // Debugging.
        /*
            stdout.printf(
                "keyval = %x, hw = %x, state = %x, length = %d, str = %s\n",
                evt.keyval,
                evt.hardware_keycode,
                evt.state,
                evt.length,
                evt.str
            );
        */

        switch (evt.state) {
            case 0:
                if (options.pause_paste) {
                    if (evt.keyval == Gdk.Key.Pause) {
                        synth_shift_insert();
                        return true;
                    }
                }
                return false;

            case Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK:
                return this.key_press_ctrl_shift(evt);

            case Gdk.ModifierType.CONTROL_MASK:
                return this.key_press_ctrl(evt);

            case Gdk.ModifierType.SHIFT_MASK:
                return this.key_press_shift(evt);

            case Gdk.ModifierType.MOD1_MASK:
                return this.key_press_mod1(evt);
        }

        return false;
    }

    void synth_shift_insert() {
        var evt = Gdk.EventKey();
        evt.type = Gdk.EventType.KEY_PRESS;
        evt.window = this.window;
        evt.state = Gdk.ModifierType.SHIFT_MASK;
        evt.hardware_keycode = Hw_Insert;

        evt.keyval = Gdk.Key.Insert;
        evt.length = 0;
        evt.str = "";

        evt.send_event = 0;
        evt.time = Gdk.CURRENT_TIME;

        Gtk.main_do_event((Gdk.Event) &evt);
    }

    bool key_press_ctrl_shift(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Gdk.Key.T:
                var cwd = get_cwd_of_shell();
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).new_terminal(options, cwd);
                }
                return true;
            case Gdk.Key.N:
                new UWindow(options, get_cwd_of_shell());
                return true;
            case Gdk.Key.Left:
            case Gdk.Key.Page_Up:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).reorder_page(this, -1);
                }
                return true;
            case Gdk.Key.Right:
            case Gdk.Key.Page_Down:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).reorder_page(this, 1);
                }
                return true;
        }
        return false;
    }

    bool key_press_ctrl(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Gdk.Key.Page_Up:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).previous_page();
                }
                return true;
            case Gdk.Key.Page_Down:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).do_next_page();
                }
                return true;
        }
        return false;
    }

    bool key_press_shift(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Gdk.Key.Left:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).previous_page();
                }
                return true;
            case Gdk.Key.Right:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).do_next_page();
                }
                return true;
            case Gdk.Key.Down:
                var p = this.parent_notebook;
                if (p != null) {
                    ((!) p).new_terminal(options, get_cwd_of_shell());
                }
                return true;
        }
        return false;
    }

    bool key_press_mod1(Gdk.EventKey evt) {
        if (evt.keyval >= Gdk.Key.@0 && evt.keyval <= Gdk.Key.@9) {
            int n = (int) evt.keyval - Gdk.Key.@0;
            int page = (n + 9) % 10;
            var p = this.parent_notebook;
            if (p != null) {
                ((!) p).do_select_page(page);
            }
            return true;
        }
        return false;
    }

    string? get_cwd_of_shell() {
        if (shell_pid == null) {
            shell_pid = get_pid_of_shell();
            if (shell_pid == null) {
                return null;
            }
        }
        try {
            var pid = (!) shell_pid;
            // Linux-specific:
            return FileUtils.read_link(@"/proc/$pid/cwd");
        }
        catch (FileError e) {
            stderr.printf("Error getting cwd: %s\n", e.message);
            return null;
        }
    }

    string? get_pid_of_shell() {
        try {
            string[] argv = {"pgrep", "-P", terminal_pid.to_string(), "-n"};
            string stdout;
            Process.spawn_sync(null, argv, null, SpawnFlags.SEARCH_PATH, null,
                out stdout, null, null);
            return stdout.chomp(); // generates C compiler warning
        }
        catch (SpawnError e) {
            stderr.printf("Error calling pgrep: %s\n", e.message);
            return null;
        }
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
