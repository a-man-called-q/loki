package main

import "core:fmt"
import "core:os"
import "core:path/filepath"

// cmd_build handles `loki build [app]`. With no app given, it builds every
// app under apps/.
cmd_build :: proc(args: []string) -> int {
	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	if len(args) > 0 {
		return build_one(root, args[0])
	}

	apps_dir, _ := filepath.join({root, "apps"}, context.temp_allocator)
	app_dirs := discover_packages(apps_dir, context.temp_allocator)
	if len(app_dirs) == 0 {
		fmt.eprintln("error: no apps found under apps/")
		return 1
	}

	exit_code := 0
	for dir in app_dirs {
		name := filepath.base(dir)
		if code := build_one(root, name); code != 0 {
			exit_code = code
		}
	}
	return exit_code
}

@(private)
build_one :: proc(root: string, app_name: string) -> int {
	app_path, _ := filepath.join({root, "apps", app_name}, context.temp_allocator)
	if !os.exists(app_path) {
		fmt.eprintfln("error: no app named %q (looked for %s)", app_name, app_path)
		return 1
	}

	bin_dir, _ := filepath.join({root, "bin"}, context.temp_allocator)
	if !os.exists(bin_dir) && os.make_directory_all(bin_dir) != nil {
		fmt.eprintfln("error: couldn't create %s", bin_dir)
		return 1
	}

	out_path, _ := filepath.join({root, "bin", app_name}, context.temp_allocator)
	out_flag := fmt.tprintf("-out:%s", out_path)
	flags := manifest_app_flags(root, app_name)
	all_flags := make([dynamic]string, context.temp_allocator)
	append(&all_flags, out_flag)
	for f in flags {
		append(&all_flags, f)
	}

	fmt.printfln("building %s...", app_name)
	rel_path, _ := filepath.join({"apps", app_name}, context.temp_allocator)
	return run_odin(.Build, root, rel_path, all_flags[:])
}
