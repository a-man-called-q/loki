package prompt

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"
import "local:cli/style"
import "local:cli/term"

@(private)
spinner_frames := [?]string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

Spinner :: struct {
	message: string,
	active:  bool,
	tty:     bool,
	th:      ^thread.Thread,
}

// spinner_start begins an animated spinner on its own thread. In
// non-interactive mode it just prints message once and returns a Spinner
// that spinner_stop treats as a no-op animation.
spinner_start :: proc(message: string) -> ^Spinner {
	s := new(Spinner)
	s.message = message
	s.tty = term.is_tty()

	if !s.tty {
		fmt.println(message)
		return s
	}

	sync.atomic_store(&s.active, true)
	fmt.print(style.HIDE_CURSOR)
	s.th = thread.create_and_start_with_poly_data(s, spin_loop)
	return s
}

@(private)
spin_loop :: proc(s: ^Spinner) {
	frame := 0
	for sync.atomic_load(&s.active) {
		fmt.printf("\r%s %s", spinner_frames[frame % len(spinner_frames)], s.message)
		frame += 1
		time.sleep(80 * time.Millisecond)
	}
}

// spinner_stop halts the animation, clears the line, prints final_message
// if non-empty, and frees s.
spinner_stop :: proc(s: ^Spinner, final_message: string = "") {
	if s.tty {
		sync.atomic_store(&s.active, false)
		thread.join(s.th)
		thread.destroy(s.th)
		fmt.print(style.CLEAR_LINE + style.CR + style.SHOW_CURSOR)
	}
	if final_message != "" {
		fmt.println(final_message)
	}
	free(s)
}
