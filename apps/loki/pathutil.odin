package main

import "core:os"
import "core:path/filepath"
import "core:strings"

// find_in_path searches PATH for an executable named name, returning its
// full path. The returned string is allocated with allocator.
find_in_path :: proc(name: string, allocator := context.allocator) -> (path: string, ok: bool) {
	path_env := os.get_env("PATH", context.temp_allocator)
	rest := path_env
	for dir in strings.split_iterator(&rest, ":") {
		if dir == "" {
			continue
		}
		candidate, _ := filepath.join({dir, name}, context.temp_allocator)
		if os.exists(candidate) {
			return strings.clone(candidate, allocator), true
		}
	}
	return "", false
}
