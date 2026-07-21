package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
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
	name := args[0] if len(args) > 0 else prompt.input("project name")
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
	local_dir, _ := filepath.join({name, "packages", "local"}, context.temp_allocator)
	vendor_dir, _ := filepath.join({name, "packages", "vendor"}, context.temp_allocator)
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

	main_path, _ := filepath.join({app_dir, "main.odin"}, context.temp_allocator)
	main_src := render_app_main(app_name)
	if os.write_entire_file(main_path, main_src) != nil {
		fmt.eprintfln("error: couldn't write %s", main_path)
		return 1
	}

	m := Manifest{
		name             = name,
		description      = description,
		odin_min_version = ODIN_VERSION,
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

	name := args[0] if len(args) > 0 else prompt.input("app name")
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

	fmt.printfln("created apps/%s", name)
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

	pkg_dir, _ := filepath.join({root, "packages", "local", name}, context.temp_allocator)
	if os.exists(pkg_dir) {
		fmt.eprintfln("error: packages/local/%s already exists", name)
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

	fmt.printfln("created packages/local/%s", name)
	fmt.printfln(`  import "local:%s"`, name)
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
