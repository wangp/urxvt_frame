/*
 * TODO
 *
 * open new tab in cwd of current tab
 * tab titles
 * activity monitoring
 * pause paste
 * get rid of blinking (notebook black background?)
 * some configurability
 */

using GLib;
using Gtk;

void main(string[] argv) {
    Gtk.init(ref argv);
    var window = new UFrame();
    window.set_default_size(700, 400);
    window.show_all();
    Gtk.main();
}

class UFrame : Gtk.Window {

    construct {
        this.title = "urxvt-frame";
        this.destroy += Gtk.main_quit;

        var notebook = new UNotebook();
        this.add(notebook);
    }
}

class UNotebook : Gtk.Notebook {

    construct {
        //this.can_focus = false;
        this.scrollable = true;
        this.page_removed += this.page_removed_hook;
        this.new_terminal();
    }

    void page_removed_hook() {
        if (this.get_n_pages() == 0) {
            Gtk.main_quit();
        }
    }

    public void new_terminal() {
        var rxvt = new URxvt(this);
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

    URxvt(UNotebook notebook) {
        this.parent_notebook = notebook; 
    }

    construct {
        this.can_focus = true;
        this.border_width = 0;

        this.realize += realize_hook;
        this.plug_added += plug_added_hook;
        this.map_event += map_event_hook;
        this.key_press_event += key_press_event_hook;
    }

    public UNotebook parent_notebook {
        get;
        construct set;
    }

    void realize_hook() {
        // XXX this shouldn't be a pointer
        weak Gdk.NativeWindow id = this.get_id();

        // should use safer routines
        // and look up shell
        var cmd = "urxvtc -embed 0x%x -pe -tabbed -e /bin/zsh".printf(id);
        try {
            Process.spawn_command_line_async(cmd);
        }
        catch (SpawnError e) {
            // do something
        }
    }

    void plug_added_hook() {
        // stdout.printf("plug_added\n");
    }

    bool map_event_hook() {
        // stdout.printf("map_event\n");
        // Will be called when the tab is switched-to.
        this.grab_focus();
        return false;
    }

    // The Vala bindings do not yet include Gdk keysyms.
    const uint Key_0 = 0x030;
    const uint Key_1 = 0x031;
    const uint Key_2 = 0x032;
    const uint Key_3 = 0x033;
    const uint Key_4 = 0x034;
    const uint Key_5 = 0x035;
    const uint Key_6 = 0x036;
    const uint Key_7 = 0x037;
    const uint Key_8 = 0x038;
    const uint Key_9 = 0x039;
    const uint Key_Left = 0xff51;
    const uint Key_Right = 0xff53;
    const uint Key_Down = 0xff54;
    const uint Key_Pause = 0xff13;
    const uint Key_T = 0x054;
    const uint Key_t = 0x074;
    const uint Mod_Ctrl_Shift = Gdk.ModifierType.CONTROL_MASK
                              | Gdk.ModifierType.SHIFT_MASK;

    bool key_press_event_hook(URxvt me, Gdk.EventKey evt) {
        // stdout.printf("keyval = %x, state = %x\n", evt.keyval, evt.state);
        switch (evt.state) {
            case Mod_Ctrl_Shift:
                return this.key_press_ctrl_shift(evt);
            case Gdk.ModifierType.SHIFT_MASK:
                return this.key_press_shift(evt);
            case Gdk.ModifierType.MOD1_MASK:
                return this.key_press_mod1(evt);
        }
        if (evt.keyval == Key_Pause) {
            // XXX how to send Shift-Insert to urxvt?
            return true;
        }
        return false;
    }

    bool key_press_ctrl_shift(Gdk.EventKey evt) {
        if (evt.keyval == Key_T) {
            this.parent_notebook.new_terminal();
            return true;
        }
        return false;
    }

    bool key_press_shift(Gdk.EventKey evt) {
        switch (evt.keyval) {
            case Key_Left:
                this.parent_notebook.previous_page();
                return true;
            case Key_Right:
                this.parent_notebook.next_page();
                return true;
            case Key_Down:
                this.parent_notebook.new_terminal();
                return true;
        }
        return false;
    }

    bool key_press_mod1(Gdk.EventKey evt) {
        if (evt.keyval >= Key_1 && evt.keyval <= Key_9) {
            this.parent_notebook.select_page((int)evt.keyval - (int)Key_1);
            return true;
        }
        if (evt.keyval == Key_0) {
            this.parent_notebook.select_page(9);
            return true;
        }
        return false;
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
