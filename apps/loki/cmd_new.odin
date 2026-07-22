package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "local:cli/prompt"

// cmd_new handles `loki new <name>`, `loki new app <name>` and
// `loki new pkg <name>`.
cmd_new :: proc(args: []string) -> int {
	if len(args) > 0 && args[0] == "app" {
		return cmd_new_app(args[1:])
	}
	if len(args) > 0 && args[0] == "pkg" {
		return cmd_new_pkg(args[1:])
	}
	return cmd_new_project(args)
}

@(private)
cmd_new_project :: proc(args: []string) -> int {
	positional, target_ids, has_target_flag, parse_ok := parse_target_flag(args)
	if !parse_ok {
		return 1
	}

	name := positional[0] if len(positional) > 0 else prompt.input("project name")
	if name == "" {
		fmt.eprintln("error: project name required (usage: loki new <name>)")
		return 1
	}
	if !valid_name(name) {
		fmt.eprintfln("error: invalid project name %q (use letters, digits, underscore; must start with a letter)", name)
		return 1
	}
	if os.exists(name) {
		fmt.eprintfln("error: %s already exists", name)
		return 1
	}

	description := prompt.input("description", "")
	app_name := prompt.input("first app name", "hello")
	if !valid_name(app_name) {
		fmt.eprintfln("error: invalid app name %q", app_name)
		return 1
	}

	app_dir, _ := filepath.join({name, "apps", app_name}, context.temp_allocator)
	local_dir, _ := filepath.join({name, COLLECTION_LOCAL_DIR}, context.temp_allocator)
	vendor_dir, _ := filepath.join({name, COLLECTION_VENDOR_DIR}, context.temp_allocator)
	scaffold_dirs := []string{app_dir, local_dir, vendor_dir}
	for d in scaffold_dirs {
		if os.make_directory_all(d) != nil {
			fmt.eprintfln("error: couldn't create %s", d)
			return 1
		}
	}

	gitignore_path, _ := filepath.join({name, ".gitignore"}, context.temp_allocator)
	if os.write_entire_file(gitignore_path, TEMPLATE_GITIGNORE) != nil {
		fmt.eprintfln("error: couldn't write %s", gitignore_path)
		return 1
	}

	ols_path, _ := filepath.join({name, "ols.json"}, context.temp_allocator)
	if os.write_entire_file(ols_path, render_ols_json()) != nil {
		fmt.eprintfln("error: couldn't write %s", ols_path)
		return 1
	}

	main_path, _ := filepath.join({app_dir, "main.odin"}, context.temp_allocator)
	main_src := render_app_main(app_name)
	if os.write_entire_file(main_path, main_src) != nil {
		fmt.eprintfln("error: couldn't write %s", main_path)
		return 1
	}

	if !has_target_flag {
		target_ids = prompt_platform_targets()
	}

	m := Manifest{
		name             = name,
		description      = description,
		odin_min_version = ODIN_VERSION,
	}
	if len(target_ids) > 0 {
		m.apps = make(map[string]App_Config, context.temp_allocator)
		m.apps[app_name] = App_Config{targets = target_ids}
	}
	if !save_manifest(name, m) {
		fmt.eprintfln("error: couldn't write loki.json in %s", name)
		return 1
	}

	if !run_git(name, []string{"init", "-q"}) {
		fmt.eprintln("warning: `git init` failed; you can run it yourself later")
	}

	fmt.println()
	fmt.printfln("created %s", name)
	if len(target_ids) > 0 {
		fmt.printfln("  targets: %s", strings.join(target_ids, ", "))
	}
	fmt.println("next steps:")
	fmt.printfln("  cd %s", name)
	fmt.printfln("  loki run %s", app_name)
	return 0
}

@(private)
cmd_new_app :: proc(args: []string) -> int {
	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	positional, target_ids, has_target_flag, parse_ok := parse_target_flag(args)
	if !parse_ok {
		return 1
	}

	name := positional[0] if len(positional) > 0 else prompt.input("app name")
	if !valid_name(name) {
		fmt.eprintfln("error: invalid app name %q (use letters, digits, underscore; must start with a letter)", name)
		return 1
	}

	app_dir, _ := filepath.join({root, "apps", name}, context.temp_allocator)
	if os.exists(app_dir) {
		fmt.eprintfln("error: apps/%s already exists", name)
		return 1
	}
	if os.make_directory_all(app_dir) != nil {
		fmt.eprintfln("error: couldn't create %s", app_dir)
		return 1
	}

	main_path, _ := filepath.join({app_dir, "main.odin"}, context.temp_allocator)
	main_src := render_app_main(name)
	if os.write_entire_file(main_path, main_src) != nil {
		fmt.eprintfln("error: couldn't write %s", main_path)
		return 1
	}

	if !has_target_flag {
		target_ids = prompt_platform_targets()
	}
	if len(target_ids) > 0 && !save_app_targets(root, name, target_ids) {
		fmt.eprintln("warning: app created but couldn't record targets in loki.json")
	}

	fmt.printfln("created apps/%s", name)
	if len(target_ids) > 0 {
		fmt.printfln("  targets: %s", strings.join(target_ids, ", "))
	}
	fmt.printfln("  loki run %s", name)
	return 0
}

@(private)
cmd_new_pkg :: proc(args: []string) -> int {
	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	name := args[0] if len(args) > 0 else prompt.input("package name")
	if !valid_name(name) {
		fmt.eprintfln("error: invalid package name %q (use letters, digits, underscore; must start with a letter)", name)
		return 1
	}

	pkg_dir, _ := filepath.join({root, COLLECTION_LOCAL_DIR, name}, context.temp_allocator)
	if os.exists(pkg_dir) {
		fmt.eprintfln("error: %s/%s already exists", COLLECTION_LOCAL_DIR, name)
		return 1
	}
	if os.make_directory_all(pkg_dir) != nil {
		fmt.eprintfln("error: couldn't create %s", pkg_dir)
		return 1
	}

	src_path, _ := filepath.join({pkg_dir, fmt.tprintf("%s.odin", name)}, context.temp_allocator)
	src := render_pkg_main(name)
	if os.write_entire_file(src_path, src) != nil {
		fmt.eprintfln("error: couldn't write %s", src_path)
		return 1
	}

	fmt.printfln("created %s/%s", COLLECTION_LOCAL_DIR, name)
	fmt.printfln(`  import "%s:%s"`, COLLECTION_LOCAL_NAME, name)
	return 0
}

// valid_name reports whether name is safe to use as a directory name and a
// valid Odin identifier (used directly in generated package declarations).
@(private)
valid_name :: proc(name: string) -> bool {
	if len(name) == 0 {
		return false
	}
	for r, i in name {
		is_letter := (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z')
		is_digit := r >= '0' && r <= '9'
		if i == 0 {
			if !is_letter {
				return false
			}
			continue
		}
		if !is_letter && !is_digit && r != '_' {
			return false
		}
	}
	return true
}

// parse_target_flag pulls a `--target=id1,id2` flag out of args, checking
// every id against PLATFORMS. has_target_flag distinguishes "no --target
// given" from "--target= given with nothing after it" — the former falls
// back to the interactive picker, the latter means "host only" explicitly.
@(private)
parse_target_flag :: proc(args: []string) -> (positional: []string, target_ids: []string, has_target_flag: bool, ok: bool) {
	pos := make([dynamic]string, context.temp_allocator)
	ids := make([dynamic]string, context.temp_allocator)

	for a in args {
		if !strings.has_prefix(a, "--target=") {
			append(&pos, a)
			continue
		}
		has_target_flag = true
		raw := strings.trim_prefix(a, "--target=")
		for part in strings.split_iterator(&raw, ",") {
			id := strings.trim_space(part)
			if id == "" {
				continue
			}
			if _, found := find_platform(id); !found {
				fmt.eprintfln("error: unknown target %q — see README for supported ids", id)
				return nil, nil, true, false
			}
			append(&ids, id)
		}
	}
	return pos[:], ids[:], has_target_flag, true
}

// prompt_platform_targets offers the interactive cross-compile picker. In
// non-interactive contexts (no TTY) it returns nil, matching loki's
// original host-only build behaviour.
@(private)
prompt_platform_targets :: proc() -> []string {
	labels := make([]string, len(PLATFORMS), context.temp_allocator)
	for p, i in PLATFORMS {
		labels[i] = p.label
	}

	question := "cross-compile targets (space to toggle, enter for host-only)"
	indices, ok := prompt.multiselect(question, labels)
	if !ok || len(indices) == 0 {
		return nil
	}

	ids := make([]string, len(indices))
	for idx, i in indices {
		ids[i] = PLATFORMS[idx].id
	}
	return ids
}

// save_app_targets records target_ids under apps[app_name].targets in
// project_root's loki.json, preserving any other config already there.
@(private)
save_app_targets :: proc(project_root: string, app_name: string, target_ids: []string) -> bool {
	m, ok := load_manifest(project_root, context.temp_allocator)
	if !ok {
		return false
	}
	if m.apps == nil {
		m.apps = make(map[string]App_Config, context.temp_allocator)
	}
	cfg := m.apps[app_name]
	cfg.targets = target_ids
	m.apps[app_name] = cfg
	return save_manifest(project_root, m)
}
