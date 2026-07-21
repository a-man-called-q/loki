package main

import "core:fmt"

TEMPLATE_GITIGNORE :: `bin/
*.dSYM/
`

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
