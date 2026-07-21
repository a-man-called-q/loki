package style

import "core:terminal"
import "core:testing"

@(test)
test_colorize_raw_wraps_and_resets :: proc(t: ^testing.T) {
	testing.expect_value(t, colorize_raw("hi", .Red), "\x1b[31mhi\x1b[0m")
}

@(test)
test_bold_raw_wraps_and_resets :: proc(t: ^testing.T) {
	testing.expect_value(t, bold_raw("hi"), "\x1b[1mhi\x1b[0m")
}

@(test)
test_colorize_disabled_is_passthrough :: proc(t: ^testing.T) {
	prev := terminal.color_enabled
	terminal.color_enabled = false
	defer terminal.color_enabled = prev

	testing.expect_value(t, colorize("hi", .Red), "hi")
}

@(test)
test_bold_disabled_is_passthrough :: proc(t: ^testing.T) {
	prev := terminal.color_enabled
	terminal.color_enabled = false
	defer terminal.color_enabled = prev

	testing.expect_value(t, bold("hi"), "hi")
}

@(test)
test_cursor_up_default :: proc(t: ^testing.T) {
	testing.expect_value(t, cursor_up(), "\x1b[1A")
}

@(test)
test_cursor_up_n :: proc(t: ^testing.T) {
	testing.expect_value(t, cursor_up(3), "\x1b[3A")
}

@(test)
test_cursor_down_n :: proc(t: ^testing.T) {
	testing.expect_value(t, cursor_down(2), "\x1b[2B")
}
