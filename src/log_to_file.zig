// Copyright 2024 - 2025, Kristófer Reykjalín and the log_to_file contributors.
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

pub const Options = struct {
    log_file_name: ?[]const u8 = null,
    storage_path: ?[]const u8 = null,
};

const PrivateOptions = struct {
    log_file_name: []const u8,
    storage_path: ?[]const u8 = null,
};

var options: PrivateOptions = if (@hasDecl(root, "log_to_file_options"))
    .{
        .log_file_name = root.log_to_file_options.log_file_name orelse "out.log",
        .storage_path = if (root.log_to_file_options.storage_path) |p|
            p
        else if (builtin.mode == .Debug)
            "logs"
        else
            null,
    }
else
    .{
        .log_file_name = "out.log",
        .storage_path = if (builtin.mode == .Debug)
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

fn maybeInitStoragePath() void {
    if (options.storage_path != null) return;

    const home = std.process.getEnvVarOwned(fba, "HOME") catch {
        return;
    };

    options.storage_path = std.fs.path.join(fba, &.{
        home,
        ".local",
        "logs",
    }) catch {
        options.storage_path = "logs";
        return;
    };
}

pub fn log_to_file(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    maybeInitStoragePath();
    if (options.storage_path == null) return;

    // Get level text and log prefix.
    // See https://ziglang.org/documentation/0.14.0/std/#std.log.defaultLog.
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    // Get a handle for the log file.
    const cwd = std.fs.cwd();
    const log_dir = cwd.makeOpenPath(options.storage_path.?, .{}) catch return;
    const log = log_dir.createFile(
        options.log_file_name,
        .{ .truncate = false },
    ) catch return;

    // Move the write index to the end of the file.
    log.seekFromEnd(0) catch return;

    // Get a writer.
    // See https://ziglang.org/documentation/0.14.0/std/#std.log.defaultLog.
    const log_writer = log.writer();
    var bw = std.io.bufferedWriter(log_writer);
    const writer = bw.writer();

    // We could be logging from different threads so we use a mutex here.
    write_to_log_mutex.lock();
    defer write_to_log_mutex.unlock();

    // Write to the log file.
    // See https://ziglang.org/documentation/0.14.0/std/#std.log.defaultLog.
    nosuspend {
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}
