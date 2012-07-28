SRCS := urxvt_frame.vala options.vala gdkkeysyms.vapi aux.vapi

urxvt_frame: $(SRCS)
	valac $(SRCS) --pkg gtk+-2.0 --pkg posix
