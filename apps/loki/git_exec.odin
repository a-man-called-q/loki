package main

import "core:os"
import "core:strings"

// run_git invokes git with args in working_dir, streaming output straight
// through. Returns true on success (exit code 0).
run_git :: proc(working_dir: string, args: []string) -> bool {
	command := make([dynamic]string, context.temp_allocator)
	append(&command, "git")
	for a in args {
		append(&command, a)
	}
	return exec_passthrough(working_dir, command[:]) == 0
}

// git_capture runs git with args in working_dir and returns its trimmed
// stdout. ok is false if git couldn't be launched or exited non-zero.
git_capture :: proc(working_dir: string, args: []string) -> (output: string, ok: bool) {
	command := make([dynamic]string, context.temp_allocator)
	append(&command, "git")
	for a in args {
		append(&command, a)
	}
	state, stdout, _, err := os.process_exec(os.Process_Desc{
		working_dir = working_dir,
		command     = command[:],
	}, context.temp_allocator)
	if err != nil || !state.success {
		return "", false
	}
	return strings.trim_space(string(stdout)), true
}
