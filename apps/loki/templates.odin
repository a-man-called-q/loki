package main

import "core:fmt"

TEMPLATE_GITIGNORE :: `bin/
*.dSYM/
`

// render_ols_json points the Odin language server (github.com/DanielGavin/ols)
// at loki's two collections, reusing the same COLLECTION_* constants
// run_odin builds -collection: flags from — one place defines what "local"
// and "deps" mean, and where they point, instead of the flags and this file
// drifting apart. Unlike loki.json's apps map, this never needs updating as
// packages are added — both collections are whole directories.
render_ols_json :: proc() -> string {
	return fmt.tprintf(
		`{{
	"$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/ols.schema.json",
	"collections": [
		{{ "name": "%s", "path": "%s" }},
		{{ "name": "%s", "path": "%s" }}
	]
}}
`,
		COLLECTION_LOCAL_NAME,
		COLLECTION_LOCAL_DIR,
		COLLECTION_VENDOR_NAME,
		COLLECTION_VENDOR_DIR,
	)
}

// render_app_main returns the starter main.odin for a new app. The braces
// around the proc body are doubled ({{ }}) because fmt.tprintf's format
// string also understands {}-style verbs, not just %-verbs — a lone brace
// would be parsed as one and blow up the output.
render_app_main :: proc(app_name: string) -> string {
	return fmt.tprintf(
		`package main

import "core:fmt"

main :: proc() {{
	fmt.println("Hello from %s!")
}}
`,
		app_name,
	)
}

// render_pkg_main returns the starter .odin file for a new local package.
render_pkg_main :: proc(pkg_name: string) -> string {
	return fmt.tprintf("package %s\n", pkg_name)
}
