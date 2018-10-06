using GLib;
using Gtk;

int main(string[] argv) {
    if (!Options.load_options()) {
        return 1;
    }

    try {
        Options.parse_command_line_options(argv);
    }
    catch (OptionError e) {
        stdout.printf("%s\n", e.message);
        return 1;
    }

    Gtk.init(ref argv);
    new_notebook();
    Gtk.main();
    return 0;
}

void new_notebook() {
    var window = new UFrame();
    window.set_default_size(700, 400);
    window.show_all();
}

class UFrame : Gtk.Window {

    static List<UFrame> all_frames;

    construct {
        this.title = "urxvt-frame";

        var notebook = new UNotebook();
        this.add(notebook);

        this.destroy.connect(this.on_destroy);

        all_frames.append(this);
    }

    void on_destroy() {
        all_frames.remove(this);
        if (all_frames.length() == 0) {
            Gtk.main_quit();
        }
    }
}

class UNotebook : Gtk.Notebook {

    int counter = 0;

    construct {
        this.flags &= ~WidgetFlags.CAN_FOCUS;
        this.scrollable = true;
        this.page_removed.connect(this.on_page_removed);

        this.new_terminal();
    }

    void on_page_removed(Gtk.Widget child, uint page_num) {
        if (this.get_n_pages() == 0) {
            // p can be null if the whole window is closed.
            var p = this.get_parent();
            if (p != null) {
                p.destroy();
            }
        }
    }

    public void new_terminal() {
        var n = this.counter++;
        var rxvt = new URxvt();
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

    public void shift_page(Gtk.Widget child, int delta) {
        var page = this.get_current_page() + delta;
        if (page >= 0 && page < this.get_n_pages()) {
            this.reorder_child(child, page);
        }
    }
}

class URxvt : Gtk.Socket {

    static bool first_terminal = true;
    bool is_first_terminal;
    Pid terminal_pid;

    construct {
        this.is_first_terminal = URxvt.first_terminal;
        URxvt.first_terminal = false;

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

    UNotebook parent_notebook {
        get {
            return this.get_parent() as UNotebook;
        }
    }

    void on_realize() {
        // XXX this shouldn't be a pointer
        weak Gdk.NativeWindow id = this.get_id();

        string[] argv = Options.terminal_command;
        argv += "-embed";
        argv += "0x%lx".printf((ulong) id);
        argv += "-e";
        if (this.is_first_terminal) {
            foreach (var arg in Options.first_command()) {
                argv += arg;
            }
        } else {
            foreach (var arg in Options.default_command) {
                argv += arg;
            }
        }

        try {
            Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH,
                null, out terminal_pid);
        }
        catch (SpawnError e) {
            stderr.printf("Error running `%s'.\n", string.joinv(" ", argv));
        }
    }

    void on_plug_added() {
        // stdout.printf("plug_added\n");
    }

    bool on_map_event() {
        // stdout.printf("map_event\n");
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
                if (Options.pause_paste) {
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
                this.parent_notebook.new_terminal();
                return true;
            case Gdk.Key.N:
                new_notebook();
                return true;
            case Gdk.Key.Left:
            case Gdk.Key.Page_Up:
                this.parent_notebook.shift_page(this, -1);
                return true;
            case Gdk.Key.Right:
            case Gdk.Key.Page_Down:
                this.parent_notebook.shift_page(this, 1);
                return true;
        }
        return false;
    }

    bool key_press_ctrl(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Gdk.Key.Page_Up:
                this.parent_notebook.previous_page();
                return true;
            case Gdk.Key.Page_Down:
                this.parent_notebook.do_next_page();
                return true;
        }
        return false;
    }

    bool key_press_shift(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Gdk.Key.Left:
                this.parent_notebook.previous_page();
                return true;
            case Gdk.Key.Right:
                this.parent_notebook.do_next_page();
                return true;
            case Gdk.Key.Down:
                this.parent_notebook.new_terminal();
                return true;
        }
        return false;
    }

    bool key_press_mod1(Gdk.EventKey evt) {
        if (evt.keyval >= Gdk.Key.@1 && evt.keyval <= Gdk.Key.@9) {
            var n = (int) evt.keyval - Gdk.Key.@1;
            this.parent_notebook.do_select_page(n);
            return true;
        }
        if (evt.keyval == Gdk.Key.@0) {
            this.parent_notebook.do_select_page(9);
            return true;
        }
        return false;
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
