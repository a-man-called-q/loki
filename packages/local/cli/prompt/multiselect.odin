package prompt

import "core:fmt"
import "core:os"
import "local:cli/style"
import "local:cli/term"

// multiselect shows an arrow-key + space-to-toggle menu and returns the
// chosen indices. In non-interactive mode, or if raw mode can't be
// enabled, it returns (default_indices, true) when default_indices is
// non-nil, otherwise (nil, false) so the caller can fail with a clear
// error. The returned slice is caller-owned.
multiselect :: proc(question: string, options: []string, default_indices: []int = nil) -> (indices: []int, ok: bool) {
	if len(options) == 0 {
		return nil, false
	}

	if !term.stdin_is_tty() || !term.is_tty() || !term.enable_raw_mode() {
		if default_indices != nil {
			return default_indices, true
		}
		return nil, false
	}
	defer term.disable_raw_mode()

	selected := make([]bool, len(options))
	defer delete(selected)
	for i in default_indices {
		if i >= 0 && i < len(options) {
			selected[i] = true
		}
	}

	cursor := 0
	fmt.printf("%s %s\n", style.bold(question), style.dim("(space to toggle, enter to confirm)"))
	for opt, i in options {
		print_multiselect_option(opt, i == cursor, selected[i])
	}
	fmt.print(style.HIDE_CURSOR)
	defer fmt.print(style.SHOW_CURSOR)

	for {
		switch read_key() {
		case .Up:
			cursor = (cursor - 1 + len(options)) % len(options)
			redraw_multiselect(options, cursor, selected)
		case .Down:
			cursor = (cursor + 1) % len(options)
			redraw_multiselect(options, cursor, selected)
		case .Space:
			selected[cursor] = !selected[cursor]
			redraw_multiselect(options, cursor, selected)
		case .Enter:
			result := make([dynamic]int)
			for is_selected, i in selected {
				if is_selected {
					append(&result, i)
				}
			}
			return result[:], true
		case .Cancel:
			term.disable_raw_mode()
			fmt.print(style.SHOW_CURSOR)
			fmt.println()
			os.exit(130)
		case .Unknown:
		// ignored
		}
	}
}

@(private)
print_multiselect_option :: proc(label: string, cursor, checked: bool) {
	mark := "x" if checked else " "
	if cursor {
		fmt.printf("  %s [%s] %s\n", style.colorize(">", .Cyan), mark, style.bold(label))
	} else {
		fmt.printf("    [%s] %s\n", mark, label)
	}
}

@(private)
redraw_multiselect :: proc(options: []string, cursor: int, selected: []bool) {
	fmt.print(style.cursor_up(len(options)))
	for opt, i in options {
		fmt.print(style.CLEAR_LINE + style.CR)
		print_multiselect_option(opt, i == cursor, selected[i])
	}
}
