# log_to_file.zig

An easy way to change the default `std.log` functions to write to a file instead of logging to
STDOUT.
Simply add this to your project via

and `std.log` functions will write to a file called `log` in your current working directory.

## Usage

1. Install the library by running
   `zig fetch --save https://git.sr.ht/~reykjalin/log_to_file.zig/archive/1.0.0.tar.gz`
   in your project.
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

Now, whenever you call the `std.log` functions they should be written to a `log` file in your
current working directory.

## Configuration

If you'd like to write logs to a different path you can configure that by adding this to your root
source file (typically `src/main.zig` or similar):

```zig
// Relative to current working directory:
pub const log_to_file_path = "logs/app.log";

// Absolute path:
pub const log_to_file_path = "/var/logs/app.log";
```
