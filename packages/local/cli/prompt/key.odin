package prompt

import "core:os"

Key :: enum {
	Unknown,
	Up,
	Down,
	Enter,
	Space,
	Cancel, // Ctrl-C or a bare Esc
}

// read_key blocks for a single keypress from stdin. Requires raw mode to
// already be enabled by the caller.
@(private)
read_key :: proc() -> Key {
	b: [1]byte
	n, err := os.read(os.stdin, b[:])
	if n <= 0 || err != nil {
		return .Cancel
	}

	switch b[0] {
	case 0x03:
		return .Cancel
	case '\r', '\n':
		return .Enter
	case ' ':
		return .Space
	case 0x1b:
		return read_escape_sequence()
	}
	return .Unknown
}

@(private)
read_escape_sequence :: proc() -> Key {
	b1: [1]byte
	n1, err1 := os.read(os.stdin, b1[:])
	if n1 <= 0 || err1 != nil || b1[0] != '[' {
		// A bare Esc (no following data, or not a CSI sequence) is
		// treated as cancel.
		return .Cancel
	}

	b2: [1]byte
	n2, err2 := os.read(os.stdin, b2[:])
	if n2 <= 0 || err2 != nil {
		return .Unknown
	}

	switch b2[0] {
	case 'A':
		return .Up
	case 'B':
		return .Down
	}
	return .Unknown
}
