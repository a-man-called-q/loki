package main

import "core:fmt"
import "core:os"

USAGE :: `loki — Odin monorepo tool

Usage:
  loki new <name> [--target=id,...]      Scaffold a new monorepo project
  loki new app <name> [--target=id,...]  Scaffold a new app in the current project
  loki new pkg <name>                    Scaffold a new local package in the current project
  loki add <git-url> [name]              Add a third-party package as a git submodule
  loki sync                              Init/update all vendor submodules
  loki run <app> [-- args]               Run an app
  loki build [app]                       Build an app, or every app if omitted
  loki test [target]                     Test a package, or every local package if omitted
  loki doctor                            Check that the environment is set up correctly

  --target=id,...  Cross-compile targets for a new app (see README); omit
                    to pick interactively, or press enter for host-only.
`

main :: proc() {
	args := os.args[1:]
	if len(args) == 0 {
		fmt.print(USAGE)
		os.exit(1)
	}

	cmd := args[0]
	rest := args[1:]

	exit_code: int
	switch cmd {
	case "new":
		exit_code = cmd_new(rest)
	case "add":
		exit_code = cmd_add(rest)
	case "sync":
		exit_code = cmd_sync(rest)
	case "run":
		exit_code = cmd_run(rest)
	case "build":
		exit_code = cmd_build(rest)
	case "test":
		exit_code = cmd_test(rest)
	case "doctor":
		exit_code = cmd_doctor(rest)
	case "-h", "--help", "help":
		fmt.print(USAGE)
		exit_code = 0
	case:
		fmt.eprintfln("error: unknown command %q", cmd)
		fmt.eprint(USAGE)
		exit_code = 1
	}

	os.exit(exit_code)
}
