// The Vala bindings do not yet include Gdk keysyms.
namespace Gdkk {
    // Hack.
    [CCode (cprefix = "GDK", cheader_filename = "gdk/gdkkeysyms.h")]
    public enum Digits {
	_0,
	_1,
	_2,
	_3,
	_4,
	_5,
	_6,
	_7,
	_8,
	_9,
    }

    [CCode (cprefix = "GDK_", cheader_filename = "gdk/gdkkeysyms.h")]
    public enum Keysyms {
	Left,
	Right,
	Down,
	Pause,
	N,
	T,
	Insert,
	Page_Up,
	Page_Down
    }
}

// vim: ft=cs ts=8 sts=4 sw=4 et
