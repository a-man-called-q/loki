package main

import "core:fmt"
import "core:os"

// exec_passthrough spawns command in working_dir with stdio inherited from
// the current process, waits for it to finish, and returns its exit code.
// Returns 1 if the process couldn't even be launched.
exec_passthrough :: proc(working_dir: string, command: []string) -> int {
	process, start_err := os.process_start(os.Process_Desc{
		working_dir = working_dir,
		command     = command,
		stdout      = os.stdout,
		stderr      = os.stderr,
		stdin       = os.stdin,
	})
	if start_err != nil {
		fmt.eprintfln("error: failed to launch %s: %v", command[0], start_err)
		return 1
	}

	state, wait_err := os.process_wait(process)
	if wait_err != nil {
		fmt.eprintfln("error: %v", wait_err)
		return 1
	}
	return state.exit_code
}
