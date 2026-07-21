package main

import "core:fmt"
import "core:path/filepath"

// cmd_test handles `loki test [target]`. With no target given, it runs
// every leaf package found under packages/local/.
cmd_test :: proc(args: []string) -> int {
	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	if len(args) > 0 {
		fmt.printfln("testing %s...", args[0])
		return run_odin(.Test, root, args[0], nil)
	}

	local_dir, _ := filepath.join({root, "packages", "local"}, context.temp_allocator)
	pkg_dirs := discover_packages(local_dir, context.temp_allocator)
	if len(pkg_dirs) == 0 {
		fmt.eprintln("error: no packages found under packages/local/")
		return 1
	}

	exit_code := 0
	for dir in pkg_dirs {
		rel, rel_err := filepath.rel(root, dir, context.temp_allocator)
		if rel_err != nil {
			continue
		}
		fmt.printfln("testing %s...", rel)
		if code := run_odin(.Test, root, rel, nil); code != 0 {
			exit_code = code
		}
	}
	return exit_code
}
