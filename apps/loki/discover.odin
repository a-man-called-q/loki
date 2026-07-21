package main

import "core:os"
import "core:path/filepath"
import "core:strings"

// discover_packages walks root and returns the directories that directly
// contain at least one .odin file — i.e. the leaf Odin packages under it.
discover_packages :: proc(root: string, allocator := context.allocator) -> []string {
	if !os.exists(root) {
		return nil
	}

	seen := make(map[string]bool, context.temp_allocator)
	result := make([dynamic]string, allocator)

	w := os.walker_create(root)
	defer os.walker_destroy(&w)

	for info in os.walker_walk(&w) {
		if _, err := os.walker_error(&w); err != nil {
			continue
		}
		if info.type != .Regular || !strings.has_suffix(info.name, ".odin") {
			continue
		}
		pkg_dir := filepath.dir(info.fullpath)
		if !seen[pkg_dir] {
			seen[pkg_dir] = true
			append(&result, strings.clone(pkg_dir, allocator))
		}
	}
	return result[:]
}
