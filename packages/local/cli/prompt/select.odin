package prompt

import "core:fmt"
import "core:os"
import "local:cli/style"
import "local:cli/term"

// select shows an arrow-key menu and returns the chosen index. In
// non-interactive mode, or if raw mode can't be enabled, it returns
// (default_index, true) when default_index is a valid option, otherwise
// (-1, false) so the caller can fail with a clear error.
select :: proc(question: string, options: []string, default_index: int = -1) -> (index: int, ok: bool) {
	if len(options) == 0 {
		return -1, false
	}

	has_default := default_index >= 0 && default_index < len(options)

	if !term.stdin_is_tty() || !term.is_tty() || !term.enable_raw_mode() {
		if has_default {
			return default_index, true
		}
		return -1, false
	}
	defer term.disable_raw_mode()

	cursor := default_index if has_default else 0

	fmt.printf("%s\n", style.bold(question))
	for opt, i in options {
		print_select_option(opt, i == cursor)
	}
	fmt.print(style.HIDE_CURSOR)
	defer fmt.print(style.SHOW_CURSOR)

	for {
		switch read_key() {
		case .Up:
			cursor = (cursor - 1 + len(options)) % len(options)
			redraw_select(options, cursor)
		case .Down:
			cursor = (cursor + 1) % len(options)
			redraw_select(options, cursor)
		case .Enter:
			return cursor, true
		case .Cancel:
			term.disable_raw_mode()
			fmt.print(style.SHOW_CURSOR)
			fmt.println()
			os.exit(130)
		case .Space, .Unknown:
		// ignored
		}
	}
}

@(private)
print_select_option :: proc(label: string, selected: bool) {
	if selected {
		fmt.printf("  %s %s\n", style.colorize(">", .Cyan), style.bold(label))
	} else {
		fmt.printf("    %s\n", label)
	}
}

@(private)
redraw_select :: proc(options: []string, cursor: int) {
	fmt.print(style.cursor_up(len(options)))
	for opt, i in options {
		fmt.print(style.CLEAR_LINE + style.CR)
		print_select_option(opt, i == cursor)
	}
}
