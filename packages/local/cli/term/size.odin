package term

import "core:c"
import "core:os"
import posix "core:sys/posix"

when ODIN_OS == .Darwin {
	foreign import libc_sys "system:System"
	@(private) TIOCGWINSZ :: 0x40087468
} else when ODIN_OS == .Linux {
	foreign import libc_sys "system:c"
	@(private) TIOCGWINSZ :: 0x5413
}

// ioctl's third argument is variadic in its real C prototype. This must be
// bound with #c_vararg rather than a fixed rawptr parameter — on Apple
// ARM64, variadic arguments are passed on the stack instead of in
// registers, so a fixed-parameter binding silently passes a garbage
// pointer and the call fails with EFAULT.
foreign libc_sys {
	ioctl :: proc(fd: c.int, request: c.ulong, #c_vararg args: ..any) -> c.int ---
}

@(private)
Winsize :: struct {
	row:    u16,
	col:    u16,
	xpixel: u16,
	ypixel: u16,
}

// size returns the terminal's current column and row count. If the size
// can't be determined (e.g. stdout isn't a terminal), it returns a sane
// fallback and ok = false.
size :: proc() -> (cols, rows: int, ok: bool) {
	ws: Winsize
	fd := posix.FD(os.fd(os.stdout))
	ret := ioctl(c.int(fd), c.ulong(TIOCGWINSZ), &ws)
	if ret != 0 || ws.col == 0 {
		return 80, 24, false
	}
	return int(ws.col), int(ws.row), true
}
