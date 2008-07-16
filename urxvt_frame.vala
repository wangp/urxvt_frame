/*
 * TODO
 *
 * destroy window on last tab close
 * close tab on urxvt exit
 * open new tab in cwd of current tab
 * share urxvt instances?
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

        this.new_terminal();
        this.new_terminal();
    }

    void new_terminal() {
        var rxvt = new Gtk.Socket();
        rxvt.can_focus = true;
        rxvt.border_width = 0;

        rxvt.realize += (socket) => {
            // socket == rxvt

            // XXX this shouldn't be a pointer
            weak Gdk.NativeWindow id = socket.get_id();

            // should use safer routines
            // and look up shell
            var cmd = "urxvt -embed 0x%x -pe -tabbed -e /bin/zsh".printf(id);
            try {
                Process.spawn_command_line_async(cmd);
            }
            catch (SpawnError e) {
                // do something
            }
        };

        rxvt.plug_added += () => {
            stdout.printf("plug_added\n");
        };

        rxvt.map_event += (socket) => {
            // socket == rxvt
            stdout.printf("map_event\n");
            // Will be called when the tab is switched-to.
            socket.grab_focus();
        };

        var label = new Gtk.Label("rxvt");
        this.append_page(rxvt, label);
        rxvt.show_all();

        this.set_tab_reorderable(rxvt, true);
    }
}

class UPage : Gtk.Frame {
}

// vim: ft=cs ts=8 sts=4 sw=4 et
