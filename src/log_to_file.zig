//! `log_to_file` gives you a pre-made, easily configurable logging function that you can use
//! instead of the `std.log.defaultLog` function from the Zig standard library.
//!
//! When compiled in debug mode logs will go to `./logs/<executable_name>.log`. When compiled in any
//! other mode logs will go to `~/.local/state/<executable_name>/<executable_name>.log`.
//!
//! You can change where the logs are stored, or specify a different file name for the log file
//! itself by changing `Options` in your root file.
//!
//! Copyright 2024 - 2025, Kristófer Reykjalín and the `log_to_file` contributors.
//!
//! SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

/// Use to configure where log files are stored and what the log file is called.
pub const Options = struct {
    /// Set to change what the log file will be called. If unset the file name will be
    /// `<executable_name>.log`. Falls back to `out.log` when executable name can't be determined.
    log_file_name: ?[]const u8 = null,
    /// Set to the directory where the log file will be stored. Supports absolute paths and relative
    /// paths. If set to a relative path logs will be store relative to where the executable is run
    /// from **not** where the executable is saved.
    ///
    /// If unset the logs will be stored in `./logs/` when compiled in debug mode and
    /// `~/.local/state/<executable_name>/` in any other mode.
    ///
    /// Falls back to `~/.cache/logs/out.log` if executable name can't be determined.
    storage_path: ?[]const u8 = null,
};

var options: Options = .{
    .log_file_name = if (@hasDecl(root, "log_to_file_options"))
        root.log_to_file_options.log_file_name
    else
        null,
    .storage_path = if (@hasDecl(root, "log_to_file_options") and
        root.log_to_file_options.storage_path != null)
        root.log_to_file_options.storage_path
    else if (builtin.mode == .Debug)
        "logs"
    else
        null,
};

var buffer_for_allocator: [std.fs.max_path_bytes * 10]u8 = undefined;
var fb_allocator = std.heap.FixedBufferAllocator.init(&buffer_for_allocator);
var allocator: std.heap.ThreadSafeAllocator = .{
    .child_allocator = fb_allocator.allocator(),
};
const fba = allocator.allocator();

var write_to_log_mutex: std.Thread.Mutex = .{};

fn maybeInitLogFileName() void {
    if (options.log_file_name != null) return;

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const exe_path = std.fs.selfExePath(&buf) catch {
        options.log_file_name = "out.log";
        return;
    };

    options.log_file_name = std.fmt.allocPrint(
        fba,
        "{s}.log",
        .{std.fs.path.basename(exe_path)},
    ) catch {
        options.log_file_name = "out.log";
        return;
    };
}

fn maybeInitStoragePath() void {
    if (options.storage_path != null) return;

    const home = std.process.getEnvVarOwned(fba, "HOME") catch {
        options.storage_path = "logs";
        return;
    };

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const exe_path = std.fs.selfExePath(&buf) catch {
        // Fallback to ephemeral logs in `~/.cache/logs/`.
        options.storage_path = std.fs.path.join(fba, &.{
            home,
            ".cache",
            "logs",
        }) catch {
            options.storage_path = "logs";
            return;
        };
        return;
    };
    const exe_name = std.fs.path.basename(exe_path);

    options.storage_path = std.fs.path.join(fba, &.{
        home,
        ".local",
        "state",
        exe_name,
    }) catch {
        options.storage_path = "logs";
        return;
    };
}

/// Replacement function that sends `std.log.{debug,info,warn,err}` logs to a file instead of to
/// stderr. Assign to `logFn` in `std.Options` in your root file.
///
/// When compiled in debug mode logs will go to `./logs/<executable_name>.log`. When compiled in any
/// other mode logs will go to `~/.local/state/<executable_name>/<executable_name>.log`.
///
/// You can change where the logs are stored, or specify a different file name for the log file
/// itself by changing `Options` in your root file.
pub fn log_to_file(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    maybeInitStoragePath();
    if (options.storage_path == null)
        return std.log.defaultLog(message_level, scope, format, args);

    maybeInitLogFileName();
    if (options.log_file_name == null)
        return std.log.defaultLog(message_level, scope, format, args);

    // Get level text and log prefix.
    // See https://ziglang.org/documentation/0.14.0/std/#std.log.defaultLog.
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    // We could be logging from different threads so we use a mutex here.
    write_to_log_mutex.lock();
    defer write_to_log_mutex.unlock();

    // Get a handle for the log file.
    const cwd = std.fs.cwd();

    const log_dir = cwd.makeOpenPath(options.storage_path.?, .{}) catch
        return std.log.defaultLog(message_level, scope, format, args);

    const log = log_dir.createFile(
        options.log_file_name.?,
        .{ .truncate = false },
    ) catch return std.log.defaultLog(message_level, scope, format, args);

    // Get a writer.
    // See https://ziglang.org/documentation/0.15.1/std/#std.log.defaultLog.
    var buffer: [64]u8 = undefined;
    var log_writer = log.writer(&buffer);

    // Move the write index to the end of the file.
    const end_pos = log.getEndPos() catch return std.log.defaultLog(message_level, scope, format, args);
    log_writer.seekTo(end_pos) catch return std.log.defaultLog(message_level, scope, format, args);

    var writer = &log_writer.interface;

    // Write to the log file.
    // See https://ziglang.org/documentation/0.15.1/std/#std.log.defaultLog.
    nosuspend {
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch
            return std.log.defaultLog(message_level, scope, format, args);

        writer.flush() catch
            return std.log.defaultLog(message_level, scope, format, args);
    }
}
