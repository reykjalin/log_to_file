# log_to_file.zig

An easy way to change Zig's default `std.log` functions to write to a file instead of logging to
STDOUT/STDERR.

> [!NOTE]
> **This is not a logging library!**
> It offers a function you can pass to Zig's `std_options`'s `.logFn` so `std.log` calls write to a
> file instead of STDOUT.

> [!IMPORTANT]
> **Version 2.0.0 introduced breaking changes**. Read through this readme to see what changed, or
> check [the changelog](./CHANGELOG.md).

## Usage

1. Install the library by running
   `zig fetch --save git+https://git.sr.ht/~reykjalin/log_to_file.zig`
   in your project.
    * You can also use `zig fetch --save git+https://github.com/reykjalin/log_to_file.zig.git` if you prefer.
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

Now, whenever you call the `std.log` functions they should be written to a `logs/out.log` file in
your current working directory when you make a `Debug` build, and `~/.local/logs/out.log` in a
`Relase` build.

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
//   * ./new-logs/out.log in Debug mode.
//   * ./new-logs/out.log in Release mode.
pub const log_to_file_options: ltf.Options = .{
    .storage_path = "new-logs",
};

// Logs will be saved to:
//   * ./app-logs/out.log in Debug mode.
//   * ./app-logs/out.log in Release mode.
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
