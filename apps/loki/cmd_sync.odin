package main

import "core:fmt"

// cmd_sync handles `loki sync` — initializes and updates all vendor
// submodules, e.g. after a fresh clone.
cmd_sync :: proc(args: []string) -> int {
	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	if !run_git(root, []string{"submodule", "update", "--init", "--recursive"}) {
		fmt.eprintln("error: `git submodule update` failed")
		return 1
	}

	fmt.println("synced")
	return 0
}
