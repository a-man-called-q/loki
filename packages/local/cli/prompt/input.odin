package prompt

import "core:fmt"
import "core:os"
import "core:strings"
import "local:cli/style"
import "local:cli/term"

// read_line reads a single line from stdin, stripping the trailing
// newline (and a preceding \r, if present). The returned string owns its
// memory. ok is false on EOF with nothing read.
@(private)
read_line :: proc(allocator := context.allocator) -> (line: string, ok: bool) {
	buf: [dynamic]byte
	buf.allocator = allocator

	b: [1]byte
	for {
		n, err := os.read(os.stdin, b[:])
		if n <= 0 || err != nil {
			if len(buf) == 0 {
				return "", false
			}
			break
		}
		if b[0] == '\n' {
			break
		}
		if b[0] != '\r' {
			append(&buf, b[0])
		}
	}
	return string(buf[:]), true
}

// input prompts for a line of text. In non-interactive mode (stdin isn't a
// terminal) it returns default immediately without blocking on stdin.
input :: proc(question: string, default: string = "") -> string {
	if !term.stdin_is_tty() {
		return default
	}

	if default != "" {
		fmt.printf("%s %s: ", style.bold(question), style.dim(fmt.tprintf("(%s)", default)))
	} else {
		fmt.printf("%s: ", style.bold(question))
	}

	line, ok := read_line()
	if !ok {
		return default
	}
	trimmed := strings.trim_space(line)
	if trimmed == "" {
		return default
	}
	return trimmed
}

// confirm asks a yes/no question. In non-interactive mode it returns
// default immediately without blocking on stdin.
confirm :: proc(question: string, default: bool = false) -> bool {
	if !term.stdin_is_tty() {
		return default
	}

	hint := "Y/n" if default else "y/N"
	fmt.printf("%s %s: ", style.bold(question), style.dim(fmt.tprintf("(%s)", hint)))

	line, ok := read_line()
	if !ok {
		return default
	}
	trimmed := strings.trim_space(line)
	if trimmed == "" {
		return default
	}
	switch trimmed[0] {
	case 'y', 'Y':
		return true
	case 'n', 'N':
		return false
	}
	return default
}
