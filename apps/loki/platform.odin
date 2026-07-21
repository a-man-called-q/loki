package main

// Platform is a curated, human-friendly cross-compile target: an id stored
// in loki.json and passed to `--target=`, plus the raw odin -target:/
// -subtarget: values it expands to. iOS and Android aren't real odin
// -target: values — they're subtargets layered on darwin_arm64 and
// linux_arm64 respectively.
Platform :: struct {
	id:        string,
	label:     string,
	target:    string,
	subtarget: string,
}

PLATFORMS := []Platform{
	{id = "darwin_arm64", label = "macOS (Apple Silicon)", target = "darwin_arm64"},
	{id = "darwin_amd64", label = "macOS (Intel)", target = "darwin_amd64"},
	{id = "linux_amd64", label = "Linux (x86_64)", target = "linux_amd64"},
	{id = "linux_arm64", label = "Linux (arm64)", target = "linux_arm64"},
	{id = "windows_amd64", label = "Windows (x86_64)", target = "windows_amd64"},
	{id = "web", label = "Web (WASM)", target = "js_wasm32"},
	{id = "ios", label = "iOS (device)", target = "darwin_arm64", subtarget = "iphone"},
	{id = "ios_simulator", label = "iOS (simulator)", target = "darwin_arm64", subtarget = "iphonesimulator"},
	{id = "android", label = "Android (arm64)", target = "linux_arm64", subtarget = "android"},
}

find_platform :: proc(id: string) -> (Platform, bool) {
	for p in PLATFORMS {
		if p.id == id {
			return p, true
		}
	}
	return {}, false
}

// host_platform_id guesses which PLATFORMS entry matches the machine loki
// itself was built for, used to preselect a sensible default in the
// interactive target picker.
host_platform_id :: proc() -> string {
	if ODIN_OS == .Darwin && ODIN_ARCH == .arm64 {
		return "darwin_arm64"
	}
	if ODIN_OS == .Darwin {
		return "darwin_amd64"
	}
	if ODIN_OS == .Linux && ODIN_ARCH == .arm64 {
		return "linux_arm64"
	}
	if ODIN_OS == .Linux {
		return "linux_amd64"
	}
	if ODIN_OS == .Windows {
		return "windows_amd64"
	}
	return ""
}
