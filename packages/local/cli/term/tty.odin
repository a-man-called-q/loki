package term

import "core:os"
import "core:terminal"

// is_tty reports whether f is attached to an interactive terminal.
is_tty :: proc(f: ^os.File = os.stdout) -> bool {
	return terminal.is_terminal(f)
}

// stdin_is_tty reports whether stdin is attached to an interactive terminal.
stdin_is_tty :: proc() -> bool {
	return terminal.is_terminal(os.stdin)
}
