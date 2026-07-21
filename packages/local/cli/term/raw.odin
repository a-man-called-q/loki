package term

import "base:runtime"
import "core:os"
import posix "core:sys/posix"

@(private)
g_saved_termios: posix.termios
@(private)
g_raw_mode_active: bool

// enable_raw_mode puts stdin into a cbreak-like mode: input is delivered
// byte-by-byte without echo or line buffering, and Ctrl-C is delivered as a
// plain 0x03 byte instead of raising SIGINT, so callers can handle it as
// part of their normal read loop. Returns false if stdin isn't a terminal
// or the termios calls fail.
enable_raw_mode :: proc() -> bool {
	if g_raw_mode_active {
		return true
	}

	fd := posix.FD(os.fd(os.stdin))
	if posix.tcgetattr(fd, &g_saved_termios) != .OK {
		return false
	}

	raw := g_saved_termios
	raw.c_lflag -= {.ECHO, .ICANON, .ISIG, .IEXTEN}
	raw.c_cc[.VMIN] = 1
	raw.c_cc[.VTIME] = 0

	if posix.tcsetattr(fd, .TCSAFLUSH, &raw) != .OK {
		return false
	}

	g_raw_mode_active = true
	posix.signal(.SIGINT, restore_on_signal)
	posix.signal(.SIGTERM, restore_on_signal)
	return true
}

// disable_raw_mode restores stdin to the terminal settings captured by the
// matching enable_raw_mode call. Safe to call even if raw mode isn't active.
disable_raw_mode :: proc() {
	if !g_raw_mode_active {
		return
	}
	fd := posix.FD(os.fd(os.stdin))
	posix.tcsetattr(fd, .TCSAFLUSH, &g_saved_termios)
	g_raw_mode_active = false
	posix.signal(.SIGINT, auto_cast posix.SIG_DFL)
	posix.signal(.SIGTERM, auto_cast posix.SIG_DFL)
}

// restore_on_signal is a safety net for termination requested from outside
// the process (e.g. `kill`) while raw mode is active — Ctrl-C from the
// keyboard itself is handled as a regular byte, not via this handler, since
// ISIG is disabled above.
@(private)
restore_on_signal :: proc "c" (sig: posix.Signal) {
	context = runtime.default_context()
	if g_raw_mode_active {
		fd := posix.FD(os.fd(os.stdin))
		posix.tcsetattr(fd, .TCSAFLUSH, &g_saved_termios)
	}
	posix._exit(130)
}
