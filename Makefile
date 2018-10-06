SRCS := urxvt_frame.vala options.vala
VALA_OPTS := --enable-deprecated --enable-experimental-non-null

urxvt_frame: $(SRCS)
	valac $(SRCS) --pkg gtk+-2.0 --pkg posix $(VALA_OPTS)
