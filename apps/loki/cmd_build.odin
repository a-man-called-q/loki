package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

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

	rel_path, _ := filepath.join({"apps", app_name}, context.temp_allocator)
	flags := manifest_app_flags(root, app_name)
	targets := manifest_app_targets(root, app_name)

	if len(targets) == 0 {
		return build_for_target(root, rel_path, app_name, "", flags)
	}

	exit_code := 0
	for id in targets {
		if code := build_for_target(root, rel_path, app_name, id, flags); code != 0 {
			exit_code = code
		}
	}
	return exit_code
}

// build_for_target runs one odin build for app_name. An empty target_id
// builds for the host, writing to bin/<app_name> exactly as loki always
// has; a PLATFORMS id cross-compiles instead, writing to
// bin/<app_name>-<target_id> (plus a platform-appropriate extension) so
// multiple targets for the same app don't clobber each other.
@(private)
build_for_target :: proc(root: string, rel_path: string, app_name: string, target_id: string, extra_flags: []string) -> int {
	out_name := app_name
	label := app_name
	target_flags := make([dynamic]string, context.temp_allocator)

	if target_id != "" {
		platform, found := find_platform(target_id)
		if !found {
			fmt.eprintfln("error: unknown target %q for app %q", target_id, app_name)
			return 1
		}
		out_name = fmt.tprintf("%s-%s", app_name, target_id)
		label = fmt.tprintf("%s (%s)", app_name, platform.label)
		append(&target_flags, fmt.tprintf("-target:%s", platform.target))
		if platform.subtarget != "" {
			append(&target_flags, fmt.tprintf("-subtarget:%s", platform.subtarget))
		}
		switch {
		case strings.has_prefix(platform.target, "windows"):
			out_name = fmt.tprintf("%s.exe", out_name)
		case strings.has_suffix(platform.target, "wasm32") || strings.has_suffix(platform.target, "wasm64p32"):
			out_name = fmt.tprintf("%s.wasm", out_name)
		}
	}

	out_path, _ := filepath.join({root, "bin", out_name}, context.temp_allocator)
	all_flags := make([dynamic]string, context.temp_allocator)
	append(&all_flags, fmt.tprintf("-out:%s", out_path))
	append(&all_flags, ..target_flags[:])
	for f in extra_flags {
		append(&all_flags, f)
	}

	fmt.printfln("building %s...", label)
	exit_code := run_odin(.Build, root, rel_path, all_flags[:])

	// odin currently exits 0 even when it can't link an unsupported
	// cross-target combination, printing a message but leaving out_path
	// missing — surface that as a real failure instead of a silent no-op.
	if target_id != "" && exit_code == 0 && !os.exists(out_path) {
		fmt.eprintfln("error: %s reported success but produced no binary at %s (host toolchain likely can't link this target yet)", label, out_path)
		return 1
	}
	return exit_code
}
