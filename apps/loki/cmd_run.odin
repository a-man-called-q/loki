package main

import "core:fmt"
import "core:os"
import "core:path/filepath"

// cmd_run handles `loki run <app> [-- args]`.
cmd_run :: proc(args: []string) -> int {
	if len(args) == 0 {
		fmt.eprintln("usage: loki run <app> [-- args]")
		return 1
	}
	app_name := args[0]
	program_args := args_after_double_dash(args[1:])

	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	app_path, _ := filepath.join({root, "apps", app_name}, context.temp_allocator)
	if !os.exists(app_path) {
		fmt.eprintfln("error: no app named %q (looked for %s)", app_name, app_path)
		return 1
	}

	flags := manifest_app_flags(root, app_name)
	rel_path, _ := filepath.join({"apps", app_name}, context.temp_allocator)
	return run_odin(.Run, root, rel_path, flags, program_args)
}

// args_after_double_dash returns the slice following the first "--" in
// args, or nil if there isn't one.
@(private)
args_after_double_dash :: proc(args: []string) -> []string {
	for a, i in args {
		if a == "--" {
			return args[i + 1:]
		}
	}
	return nil
}

// manifest_app_flags looks up apps[name].flags in project_root's loki.json.
// Returns nil if there's no manifest or no entry for name.
@(private)
manifest_app_flags :: proc(project_root: string, name: string) -> []string {
	m, ok := load_manifest(project_root, context.temp_allocator)
	if !ok {
		return nil
	}
	cfg, found := m.apps[name]
	if !found {
		return nil
	}
	return cfg.flags
}

// project_root_or_error resolves the current project root from the working
// directory, printing a clear error if there isn't one.
@(private)
project_root_or_error :: proc() -> (root: string, ok: bool) {
	cwd, cwd_err := os.get_working_directory(context.temp_allocator)
	if cwd_err != nil {
		fmt.eprintfln("error: couldn't determine working directory: %v", cwd_err)
		return "", false
	}
	root, ok = find_project_root(cwd, context.temp_allocator)
	if !ok {
		fmt.eprintln("error: not inside a loki project (no loki.json found in this or any parent directory)")
	}
	return
}
