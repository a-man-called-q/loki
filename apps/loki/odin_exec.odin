package main

import "core:fmt"

Odin_Cmd :: enum {
	Run,
	Build,
	Test,
}

// check_odin_available verifies `odin` is on PATH, printing install
// guidance and returning false if it isn't.
check_odin_available :: proc() -> bool {
	if _, found := find_in_path("odin"); found {
		return true
	}
	fmt.eprintln("error: `odin` not found on PATH")
	fmt.eprintln("  install it from https://odin-lang.org/docs/install/ (e.g. `brew install odin` on macOS)")
	return false
}

// run_odin invokes the odin compiler against target_path (relative to
// project_root) with the loki collection flags plus extra_flags, streaming
// the child's stdout/stderr/stdin straight through. Returns the child's
// exit code, or 1 if odin couldn't even be launched.
run_odin :: proc(
	cmd: Odin_Cmd,
	project_root: string,
	target_path: string,
	extra_flags: []string,
	program_args: []string = nil,
) -> int {
	if !check_odin_available() {
		return 1
	}

	command := make([dynamic]string, context.temp_allocator)
	append(&command, "odin")
	switch cmd {
	case .Run:
		append(&command, "run")
	case .Build:
		append(&command, "build")
	case .Test:
		append(&command, "test")
	}
	append(&command, target_path)
	append(&command, fmt.tprintf("-collection:local=%s/packages/local", project_root))
	append(&command, fmt.tprintf("-collection:deps=%s/packages/vendor", project_root))
	for f in extra_flags {
		append(&command, f)
	}
	if cmd == .Run && len(program_args) > 0 {
		append(&command, "--")
		for a in program_args {
			append(&command, a)
		}
	}

	return exec_passthrough(project_root, command[:])
}
