package main

import "core:fmt"

// The two collections every loki project has: the -collection: name odin
// sees them as, and the directory they point to. Defined once here because
// both halves are baked into the -collection: flags below AND ols.json's
// generated content (see render_ols_json in templates.odin) — two copies
// of the same name or path would drift out of sync silently otherwise.
COLLECTION_LOCAL_NAME :: "local"
COLLECTION_LOCAL_DIR :: "packages/local"
COLLECTION_VENDOR_NAME :: "deps"
COLLECTION_VENDOR_DIR :: "packages/vendor"

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
	append(&command, fmt.tprintf("-collection:%s=%s/%s", COLLECTION_LOCAL_NAME, project_root, COLLECTION_LOCAL_DIR))
	append(&command, fmt.tprintf("-collection:%s=%s/%s", COLLECTION_VENDOR_NAME, project_root, COLLECTION_VENDOR_DIR))
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
