// Bindings to C functions that Vala lacks.

namespace GtkAux {
    [CCode (cname="gtk_main_do_event", cheader_filename = "gtk/gtk.h")]
    public static void main_do_event_key (Gdk.EventKey event);
}

// vim: ft=cs ts=8 sts=4 sw=4 et
