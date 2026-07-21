package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

// cmd_doctor runs environment preflight checks: the odin toolchain, the
// project root, and the health of every vendor submodule.
cmd_doctor :: proc(args: []string) -> int {
	ok := true

	if path, found := find_in_path("odin", context.temp_allocator); found {
		fmt.printfln("[ok]   odin found at %s", path)
	} else {
		fmt.println("[fail] odin not found on PATH")
		fmt.println("       install it from https://odin-lang.org/docs/install/ (e.g. `brew install odin` on macOS)")
		ok = false
	}

	cwd, cwd_err := os.get_working_directory(context.temp_allocator)
	if cwd_err != nil {
		return exit_code_for(ok)
	}

	root, found := find_project_root(cwd, context.temp_allocator)
	if !found {
		fmt.println("[info] not inside a loki project (no loki.json found)")
		return exit_code_for(ok)
	}
	fmt.printfln("[ok]   loki project root at %s", root)

	if !check_vendor_status(root) {
		ok = false
	}

	if !check_cross_targets(root) {
		ok = false
	}

	return exit_code_for(ok)
}

@(private)
exit_code_for :: proc(ok: bool) -> int {
	return 0 if ok else 1
}

// check_vendor_status reports the health of every git submodule under
// packages/vendor/: uninitialized, checked out at an unexpected commit,
// merge conflicts, or local modifications (submodules aren't meant to be
// edited directly). Returns false if anything's off.
@(private)
check_vendor_status :: proc(root: string) -> bool {
	output, ok := git_capture(root, []string{"submodule", "status"})
	if !ok || output == "" {
		return true
	}

	all_ok := true
	lines := strings.split_lines(output, context.temp_allocator)
	for line in lines {
		if line == "" {
			continue
		}
		status_char := line[0]
		rest := strings.trim_left(line[1:], " ")
		fields := strings.fields(rest, context.temp_allocator)
		// Every status line is "<sha> <path> (<describe>)", so the path is
		// the second field, not the first.
		path := fields[1] if len(fields) > 1 else "?"

		switch status_char {
		case '-':
			fmt.printfln("[warn] vendor %s not initialized (run `loki sync`)", path)
			all_ok = false
		case '+':
			fmt.printfln("[warn] vendor %s checked out at a different commit than recorded", path)
			all_ok = false
		case 'U':
			fmt.printfln("[warn] vendor %s has merge conflicts", path)
			all_ok = false
		case:
			full_path, _ := filepath.join({root, path}, context.temp_allocator)
			dirty, dirty_ok := git_capture(full_path, []string{"status", "--porcelain"})
			if dirty_ok && dirty != "" {
				fmt.printfln("[warn] vendor %s has local modifications — vendor/ shouldn't be edited directly", path)
				all_ok = false
			} else {
				fmt.printfln("[ok]   vendor %s clean", path)
			}
		}
	}
	return all_ok
}

// check_cross_targets reports whether the toolchain looks ready for any
// non-host targets declared under apps[*].targets in loki.json. Odin can
// typecheck any target on any host, but linking iOS/Android output still
// depends on platform SDKs that live outside the Odin toolchain itself.
@(private)
check_cross_targets :: proc(root: string) -> bool {
	m, ok := load_manifest(root, context.temp_allocator)
	if !ok {
		return true
	}

	all_ok := true
	any_targets := false
	for app_name, cfg in m.apps {
		for id in cfg.targets {
			any_targets = true
			platform, found := find_platform(id)
			if !found {
				fmt.printfln("[warn] app %s: unknown target %q in loki.json", app_name, id)
				all_ok = false
				continue
			}
			if !check_platform_toolchain(app_name, platform) {
				all_ok = false
			}
		}
	}
	if !any_targets {
		return true
	}
	return all_ok
}

// check_platform_toolchain prints one [ok]/[warn] line for building
// app_name against platform, and reports whether it looks ready.
@(private)
check_platform_toolchain :: proc(app_name: string, platform: Platform) -> bool {
	switch platform.subtarget {
	case "iphone", "iphonesimulator":
		if ODIN_OS != .Darwin {
			fmt.printfln("[warn] %s (%s): iOS builds need Xcode's toolchain, which only runs on macOS", app_name, platform.label)
			return false
		}
		if _, found := find_in_path("xcrun"); !found {
			fmt.printfln("[warn] %s (%s): `xcrun` not found — install the Xcode command line tools", app_name, platform.label)
			return false
		}
		fmt.printfln("[ok]   %s (%s): Xcode command line tools found", app_name, platform.label)
		return true
	case "android":
		if os.get_env("ANDROID_NDK_HOME", context.temp_allocator) == "" && os.get_env("ANDROID_NDK_ROOT", context.temp_allocator) == "" {
			fmt.printfln("[warn] %s (%s): set ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) to link against the Android NDK", app_name, platform.label)
			return false
		}
		fmt.printfln("[ok]   %s (%s): Android NDK environment variable set", app_name, platform.label)
		return true
	case:
		fmt.printfln("[ok]   %s (%s): cross-compiles with the Odin toolchain, no extra SDK needed", app_name, platform.label)
		return true
	}
}
