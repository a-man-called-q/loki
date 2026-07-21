package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

// cmd_add handles `loki add <git-url> [name]`. It adds the repo as a git
// submodule under packages/vendor/<name> and records it in loki.json.
cmd_add :: proc(args: []string) -> int {
	if len(args) == 0 {
		fmt.eprintln("usage: loki add <git-url> [name]")
		return 1
	}
	url := args[0]
	name := args[1] if len(args) > 1 else derive_name_from_url(url)
	if !valid_name(name) {
		fmt.eprintfln("error: couldn't derive a valid package name from %q — pass one explicitly: loki add %s <name>", url, url)
		return 1
	}

	root, root_ok := project_root_or_error()
	if !root_ok {
		return 1
	}

	vendor_path, _ := filepath.join({root, "packages", "vendor", name}, context.temp_allocator)
	if os.exists(vendor_path) {
		fmt.eprintfln("error: packages/vendor/%s already exists", name)
		return 1
	}

	rel_vendor_path, _ := filepath.join({"packages", "vendor", name}, context.temp_allocator)
	if !run_git(root, []string{"submodule", "add", url, rel_vendor_path}) {
		fmt.eprintln("error: `git submodule add` failed")
		return 1
	}

	rev, _ := git_capture(vendor_path, []string{"rev-parse", "HEAD"})

	m, _ := load_manifest(root, context.temp_allocator)
	vendor_dyn := make([dynamic]Vendor_Entry, 0, len(m.vendor) + 1, context.temp_allocator)
	append(&vendor_dyn, ..m.vendor)
	append(&vendor_dyn, Vendor_Entry{name = name, url = url, rev = rev})
	m.vendor = vendor_dyn[:]

	if !save_manifest(root, m) {
		fmt.eprintln("warning: submodule added but couldn't update loki.json")
		return 1
	}

	fmt.printfln("added %s as packages/vendor/%s", url, name)
	fmt.printfln(`  import "deps:%s"`, name)
	return 0
}

// derive_name_from_url extracts a package name from the last path segment
// of a git URL, stripping a trailing ".git".
@(private)
derive_name_from_url :: proc(url: string) -> string {
	trimmed := strings.trim_right(url, "/")
	trimmed = strings.trim_suffix(trimmed, ".git")
	if idx := strings.last_index_byte(trimmed, '/'); idx >= 0 {
		return trimmed[idx + 1:]
	}
	return trimmed
}
