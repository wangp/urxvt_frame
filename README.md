urxvt\_frame
============

urxvt\_frame is a simple tab container for [rxvt-unicode].
It runs rxvt-unicode in a GtkNotebook widget to give a rudimentary
tabbed terminal emulator.
rxvt-unicode does have built-in tab support, but in a slightly
unconventional form.

urxvt\_frame is written in the [Vala] programming language.
Every few years I might tweak it just enough to compile with a newer
Vala compiler.  Maybe you can get it to work, too.

[rxvt-unicode]: http://software.schmorp.de/pkg/rxvt-unicode.html

[Vala]: https://live.gnome.org/Vala


Requirements
============

* rxvt-unicode
* Vala compiler
* GTK+2


Compiling
=========

With `valac` in your $PATH, run:

    make


Configuration
=============

The configuration file is located at `~/.config/urxvt_frame/urxvt_frame.conf`.
See the file `urxvt_frame.conf.sample` for details.


Usage
=====

    urxvt_frame [-e command [ args ]]


Keys
====

* Ctrl-Shift-N - new window
* Ctrl-Shift-T - new tab
* Ctrl-PageUp - previous tab
* Ctrl-PageDown - next tab
* Shift-Left - previous tab
* Shift-Right - next tab
* Shift-Down - new tab
* Ctrl-Shift-Left - reorder tab
* Ctrl-Shift-Right - reorder tab
* Ctrl-Shift-PageUp - reorder tab
* Ctrl-Shift-PageDown - reorder tab
* Alt-0 .. Alt-9 - go to tab N
* Pause - synthetic Shift-Insert key

With the `pause_paste` configuration option enabled, the Pause key sends a
synthetic Shift-Insert key to rxvt-unicode, for slightly easier text pasting.
This is rather hacky and may not work.

You can reorder the tabs by dragging them with a mouse.


Author
======

Peter Wang <novalazy@gmail.com>

