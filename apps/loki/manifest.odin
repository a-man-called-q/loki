package main

import "core:encoding/json"
import "core:os"
import "core:path/filepath"
import "core:strings"

MANIFEST_FILENAME :: "loki.json"

Vendor_Entry :: struct {
	name: string,
	url:  string,
	rev:  string,
}

App_Config :: struct {
	flags: []string,
}

Manifest :: struct {
	name:             string,
	description:      string,
	odin_min_version: string,
	vendor:           []Vendor_Entry,
	apps:             map[string]App_Config,
}

// find_project_root walks upward from start_dir looking for loki.json,
// returning the directory that contains it.
find_project_root :: proc(start_dir: string, allocator := context.allocator) -> (root: string, ok: bool) {
	dir := start_dir
	for {
		candidate, _ := filepath.join({dir, MANIFEST_FILENAME}, context.temp_allocator)
		if os.exists(candidate) {
			return strings.clone(dir, allocator), true
		}
		parent := filepath.dir(dir)
		if parent == dir {
			return "", false
		}
		dir = parent
	}
}

// load_manifest reads and parses loki.json from project_root.
load_manifest :: proc(project_root: string, allocator := context.allocator) -> (m: Manifest, ok: bool) {
	path, _ := filepath.join({project_root, MANIFEST_FILENAME}, context.temp_allocator)
	data, read_err := os.read_entire_file(path, context.temp_allocator)
	if read_err != nil {
		return {}, false
	}
	if json.unmarshal(data, &m, allocator = allocator) != nil {
		return {}, false
	}
	return m, true
}

// save_manifest writes m to loki.json in project_root as pretty-printed JSON.
save_manifest :: proc(project_root: string, m: Manifest) -> bool {
	path, _ := filepath.join({project_root, MANIFEST_FILENAME}, context.temp_allocator)
	data, err := json.marshal(m, json.Marshal_Options{pretty = true}, context.temp_allocator)
	if err != nil {
		return false
	}
	return os.write_entire_file(path, data) == nil
}
