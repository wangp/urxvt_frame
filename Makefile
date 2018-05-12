SRCS := urxvt_frame.vala options.vala

urxvt_frame: $(SRCS)
	valac $(SRCS) --pkg gtk+-2.0 --pkg posix
