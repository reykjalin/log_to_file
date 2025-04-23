# Examples

You can run the examples by running `zig build -Dexample=<example> run` where `<example>` is one
of:

1. `defaults` - demonstrates no-config behavior.
2. `custom_log_file` - demonstrates custom log file name behavior.
3. `custom_storage_path` - demonstrates custom storage path behavior.
4. `custom_storage_path_and_log_file` - demonstrates custom storage path and log file name
behavior.

## Running examples in release mode

The command above will run the examples in `Debug` mode. You can also run them in `Release` mode
with `zig build -Doptimize=<example> -Doptimize=ReleaseFast run`.

> [!IMPORTANT]
> When in release mode the `defaults` and `custom_log_file` examples will store logs in
> `~/.local/logs/out.log` and `~/.local/logs/custom-file.log` respectively.
