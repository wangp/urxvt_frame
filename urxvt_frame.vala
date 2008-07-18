using GLib;
using Gtk;
using Gdkk;

int main(string[] argv) {
    if (!Options.load_options()) {
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

        this.destroy += this.on_destroy;

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

    construct {
        this.can_focus = false;
        this.scrollable = true;
        this.page_removed += this.on_page_removed;

        this.new_terminal();
    }

    void on_page_removed() {
        if (this.get_n_pages() == 0) {
            // This can happen in the case of closing the window.
            if (this.parent != null) {
                this.parent.destroy();
            }
        }
    }

    public void new_terminal() {
        var rxvt = new URxvt();
        var label = new Gtk.Label("rxvt");
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

    public void next_page() {
        var n = this.get_n_pages();
        var page = this.get_current_page() + 1;
        if (page >= n) {
            page = 0;
        }
        this.set_current_page(page);
    }

    public void select_page(int n) {
        this.set_current_page(n);
    }
}

class URxvt : Gtk.Socket {

    construct {
        this.can_focus = true;
        this.border_width = 0;

        // Reduce the initial flicker when the terminal starts up.  Of course,
        // this assumes the terminal background colour is black.
        Gdk.Color black = { 0, 0, 0, 0 };
        this.modify_bg(Gtk.StateType.NORMAL, black);

        this.realize += on_realize;
        this.plug_added += on_plug_added;
        this.map_event += on_map_event;
        this.key_press_event += on_key_press_event;
    }

    UNotebook parent_notebook {
        get {
            // XXX is it possible to sanity check this cast?
            return (UNotebook) this.parent;
        }
    }

    void on_realize() {
        // XXX this shouldn't be a pointer
        weak Gdk.NativeWindow id = this.get_id();

        // The order of arguments matters.
        var embed = " -embed 0x%lx".printf((ulong) id);
        var cmd = Options.terminal_command + embed +
            " -e " + Options.default_command;

        try {
            // should use safer routines
            Process.spawn_command_line_async(cmd);
        }
        catch (SpawnError e) {
            stderr.printf("Error running `%s'.\n", cmd);
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

    const uint Mod_Ctrl_Shift = Gdk.ModifierType.CONTROL_MASK
                              | Gdk.ModifierType.SHIFT_MASK;

    // Hack. I don't know if this is portable.
    const ushort Hw_Insert = 0x6a;

    bool on_key_press_event(URxvt me, Gdk.EventKey evt) {
        // Debugging.
        if (false) {
            stdout.printf(
                "keyval = %x, hw = %x, state = %x, length = %d, str = %s\n",
                evt.keyval,
                evt.hardware_keycode,
                evt.state,
                evt.length,
                evt.str
            );
        }

        switch (evt.state) {
            case 0:
                if (Options.pause_paste) {
                    if (evt.keyval == Keysyms.Pause) {
                        synth_shift_insert();
                        return true;
                    }
                }
                return false;

            case Mod_Ctrl_Shift:
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

        evt.keyval = Keysyms.Insert;
        evt.length = 0;
        evt.str = "";

        evt.send_event = 0;
        evt.time = Gdk.CURRENT_TIME;

        Gtk.main_do_event((Gdk.Event) evt);
    }

    bool key_press_ctrl_shift(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Keysyms.T:
                this.parent_notebook.new_terminal();
                return true;
            case Keysyms.N:
                new_notebook();
                return true;
        }
        return false;
    }

    bool key_press_ctrl(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Keysyms.Page_Up:
                this.parent_notebook.previous_page();
                return true;
            case Keysyms.Page_Down:
                this.parent_notebook.next_page();
                return true;
        }
        return false;
    }

    bool key_press_shift(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Keysyms.Left:
                this.parent_notebook.previous_page();
                return true;
            case Keysyms.Right:
                this.parent_notebook.next_page();
                return true;
            case Keysyms.Down:
                this.parent_notebook.new_terminal();
                return true;
        }
        return false;
    }

    bool key_press_mod1(Gdk.EventKey evt) {
        if (evt.keyval >= (uint) Digits._1 && 
            evt.keyval <= (uint) Digits._9)
        {
            var n = (int) evt.keyval - (int) Digits._1;
            this.parent_notebook.select_page(n);
            return true;
        }
        if (evt.keyval == Digits._0) {
            this.parent_notebook.select_page(9);
            return true;
        }
        return false;
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
