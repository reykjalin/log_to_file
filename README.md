# log_to_file

[API docs](https://reykjalin.srht.site/docs/log_to_file/)

An easy way to change Zig's default `std.log` functions to write to a file instead of logging to
stderr.

> [!NOTE]
> **This is not a logging library!**
> It offers a function you can pass to Zig's `std_options`'s `.logFn` so `std.log` calls write to a
> file instead of stderr.

> [!IMPORTANT]
> **Version 2.0.0 introduced breaking changes**. Read through this readme to see what changed, or
> check [the changelog](./CHANGELOG.md).

## Usage

> [!IMPORTANT]
> If the logging function fails to write to the log file, e.g. due to a permissions issue, it will
> fallback to `std.log.defaultLog()` instead of silently failing.

1. Install the library by running
   `zig fetch --save https://git.sr.ht/~reykjalin/log_to_file/archive/2.0.0.tar.gz`
   in your project.
    * You can also use `zig fetch --save https://github.com/reykjalin/log_to_file/archive/refs/tags/2.0.0.zip` if you prefer.
2. Add the library as a dependency in your project's `build.zig`:

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ltf_dep = b.dependency("log_to_file", .{ .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("log_to_file", ltf_dep.module("log_to_file"));
```

3. Set the log function in your main project:

```zig
const ltf = @import("log_to_file");

pub const std_options: std.Options = .{
    .logFn = ltf.log_to_file,
};
```

Now, whenever you call the `std.log` functions they should be written to a
`logs/<executable_name>.log` file in your current working directory when you make a `Debug` build,
and `~/.local/logs/<executable_name>.log` in a `Release` build.

For example, if your executable is called `example` (as is the case with
[the examples](./examples/README.md)) the logs will be in `./logs/example.log` by default in a
`Debug` build.

## Configuration

[The examples](./examples/README.md) are a great resource to play with to understand how the
library works.

If you'd like to write logs to a different path you can configure that by adding this to your root
source file (typically `src/main.zig` or similar):

```zig
const ltf = @import("log_to_file");

// Logs will be saved to:
//   * ./logs/log in Debug mode.
//   * ~/.local/logs/log in Release mode.
pub const log_to_file_options: ltf.Options = .{
    .log_file_name = "log",
};

// Logs will be saved to:
//   * ./new-logs/<executable_name>.log in Debug mode.
//   * ./new-logs/<executable_name>.log in Release mode.
pub const log_to_file_options: ltf.Options = .{
    .storage_path = "new-logs",
};

// Logs will be saved to:
//   * /var/logs/<executable_name>.log in Debug mode.
//   * /var/logs/<executable_name>.log in Release mode.
pub const log_to_file_options: ltf.Options = .{
    .storage_path = "/var/logs",
};

// Logs will be saved to:
//   * ./app-logs/app.log in Debug mode.
//   * ./app-logs/app.log in Release mode.
pub const log_to_file_options: ltf.Options = .{
    .log_file_name = "app.log",
    .storage_path = "app-logs",
};

// Logs will be saved to:
//   * /var/logs/app.log in Debug mode.
//   * /var/logs/app.log in Release mode.
pub const log_to_file_options: ltf.Options = .{
    .log_file_name = "app.log",
    .storage_path = "/var/logs",
};
```
