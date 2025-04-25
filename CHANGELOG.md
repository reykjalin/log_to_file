# Changelog

## 2.1.0

* The default, no-config log location is now
  `~/.local/state/<executable_name>/<executable_name>.log` **in `ReleaseFast`,
  `ReleaseSmall`, and `ReleaseSafe` modes**.
* If we can't get `<executable_name>` the default location becomes `~/.cache/logs/out.log` **in
  `ReleaseFast`, `ReleaseSmall`, and `ReleaseSafe` modes**.

## 2.0.0

### Bug fixes

* Removed general purpose allocator initialization that was unused. This was optimized away by the
  Zig compiler, but the code shouldn't be there.

### Breaking changes

* `pub const log_to_file_path` no longer works. Use `pub const log_to_file_options` instead. See
  [the readme](./README.md) for deatils or take a look at [the examples](./examples/README.md).
* The default, no-config log location is now `./logs/<executable_name>.log` **in `Debug` mode**.
* The default, no-config log location is now `~/.local/logs/<executable_name>.log` **in
  `ReleaseFast`, `ReleaseSmall`, and `ReleaseSafe` modes**.

### Improvements

* The logging function will now fallback to `std.log.defaultLog()` if it fails to write to the log
  file.

## 1.0.0

* Logs to `./log` by default.
* You can change log file path by setting `pub const log_to_file_path = "/new/path/to/log"` in
  you root source file (typically `src/main.zig` or similar).
