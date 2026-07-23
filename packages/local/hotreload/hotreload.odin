package hotreload

import "core:dynlib"
import "core:os"
import "core:time"

// Watch tracks one dynamic library on disk so try_reload can tell whether
// it needs to be (re)loaded.
Watch :: struct {
	path:          string,
	symbol_prefix: string,
	handle_field:  string,
	mod_time:      time.Time,
	loaded:        bool,
}

// make_watch prepares a Watch for the dynamic library at path. symbol_prefix
// and handle_field are forwarded to dynlib.initialize_symbols as-is — see
// its doc comment for what they mean. handle_field defaults to "lib", so
// the struct passed to try_reload needs a `lib: dynlib.Library` field
// unless a different name is given.
make_watch :: proc(path: string, symbol_prefix: string, handle_field := "lib") -> Watch {
	return Watch{path = path, symbol_prefix = symbol_prefix, handle_field = handle_field}
}

// try_reload (re)loads api's symbols from w.path the first time it's
// called, and again any time w.path's mtime has advanced since the last
// (re)load — cheap enough to call every frame. dynlib.initialize_symbols
// unloads the previously loaded library itself, so callers don't need to.
//
// api must be a struct with proc-typed fields matching the library's
// exported symbol names (after symbol_prefix) plus a dynlib.Library field
// named w.handle_field — exactly what dynlib.initialize_symbols expects.
try_reload :: proc(w: ^Watch, api: ^$T) -> (reloaded: bool) {
	info, err := os.stat(w.path, context.temp_allocator)
	if err != nil {
		return false
	}
	if w.loaded && time.diff(w.mod_time, info.modification_time) <= 0 {
		return false
	}

	_, ok := dynlib.initialize_symbols(api, w.path, w.symbol_prefix, w.handle_field)
	if !ok {
		return false
	}
	w.mod_time = info.modification_time
	w.loaded = true
	return true
}
