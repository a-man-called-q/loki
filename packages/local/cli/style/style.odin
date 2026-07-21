package style

import "core:fmt"
import "core:os"
import "core:terminal"
import stdansi "core:terminal/ansi"

// color_enabled reports whether ANSI color output should be emitted:
// the environment must advertise color support (see core:terminal, which
// already respects NO_COLOR) AND stdout must actually be a terminal, so
// output redirected to a file or pipe stays plain.
@(private)
color_enabled :: proc() -> bool {
	return terminal.color_enabled && terminal.is_terminal(os.stdout)
}

Color :: enum {
	Default,
	Black,
	Red,
	Green,
	Yellow,
	Blue,
	Magenta,
	Cyan,
	White,
	Bright_Black,
	Bright_Red,
	Bright_Green,
	Bright_Yellow,
	Bright_Blue,
	Bright_Magenta,
	Bright_Cyan,
	Bright_White,
}

RESET :: stdansi.CSI + stdansi.RESET + stdansi.SGR
BOLD  :: stdansi.CSI + stdansi.BOLD + stdansi.SGR
FAINT :: stdansi.CSI + stdansi.FAINT + stdansi.SGR

CLEAR_LINE  :: stdansi.CSI + "2" + stdansi.EL
HIDE_CURSOR :: stdansi.CSI + stdansi.DECTCEM_HIDE
SHOW_CURSOR :: stdansi.CSI + stdansi.DECTCEM_SHOW
CR          :: "\r"

@(private)
fg_codes := [Color]string {
	.Default        = stdansi.CSI + stdansi.FG_DEFAULT + stdansi.SGR,
	.Black          = stdansi.CSI + stdansi.FG_BLACK + stdansi.SGR,
	.Red            = stdansi.CSI + stdansi.FG_RED + stdansi.SGR,
	.Green          = stdansi.CSI + stdansi.FG_GREEN + stdansi.SGR,
	.Yellow         = stdansi.CSI + stdansi.FG_YELLOW + stdansi.SGR,
	.Blue           = stdansi.CSI + stdansi.FG_BLUE + stdansi.SGR,
	.Magenta        = stdansi.CSI + stdansi.FG_MAGENTA + stdansi.SGR,
	.Cyan           = stdansi.CSI + stdansi.FG_CYAN + stdansi.SGR,
	.White          = stdansi.CSI + stdansi.FG_WHITE + stdansi.SGR,
	.Bright_Black   = stdansi.CSI + stdansi.FG_BRIGHT_BLACK + stdansi.SGR,
	.Bright_Red     = stdansi.CSI + stdansi.FG_BRIGHT_RED + stdansi.SGR,
	.Bright_Green   = stdansi.CSI + stdansi.FG_BRIGHT_GREEN + stdansi.SGR,
	.Bright_Yellow  = stdansi.CSI + stdansi.FG_BRIGHT_YELLOW + stdansi.SGR,
	.Bright_Blue    = stdansi.CSI + stdansi.FG_BRIGHT_BLUE + stdansi.SGR,
	.Bright_Magenta = stdansi.CSI + stdansi.FG_BRIGHT_MAGENTA + stdansi.SGR,
	.Bright_Cyan    = stdansi.CSI + stdansi.FG_BRIGHT_CYAN + stdansi.SGR,
	.Bright_White   = stdansi.CSI + stdansi.FG_BRIGHT_WHITE + stdansi.SGR,
}

@(private)
colorize_raw :: proc(text: string, c: Color) -> string {
	return fmt.tprintf("%s%s%s", fg_codes[c], text, RESET)
}

// colorize wraps text in a foreground color, resetting after. Returns text
// unchanged when color output isn't appropriate (NO_COLOR, non-TTY stdout,
// dumb terminal) — see color_enabled.
colorize :: proc(text: string, c: Color) -> string {
	if !color_enabled() {
		return text
	}
	return colorize_raw(text, c)
}

@(private)
bold_raw :: proc(text: string) -> string {
	return fmt.tprintf("%s%s%s", BOLD, text, RESET)
}

// bold wraps text in a bold escape sequence, resetting after. No-op when
// color is disabled.
bold :: proc(text: string) -> string {
	if !color_enabled() {
		return text
	}
	return bold_raw(text)
}

@(private)
dim_raw :: proc(text: string) -> string {
	return fmt.tprintf("%s%s%s", FAINT, text, RESET)
}

// dim wraps text in a faint escape sequence, resetting after. No-op when
// color is disabled.
dim :: proc(text: string) -> string {
	if !color_enabled() {
		return text
	}
	return dim_raw(text)
}

// cursor_up returns the escape sequence to move the cursor up n lines.
cursor_up :: proc(n: int = 1) -> string {
	return fmt.tprintf("%s%d%s", stdansi.CSI, n, stdansi.CUU)
}

// cursor_down returns the escape sequence to move the cursor down n lines.
cursor_down :: proc(n: int = 1) -> string {
	return fmt.tprintf("%s%d%s", stdansi.CSI, n, stdansi.CUD)
}
