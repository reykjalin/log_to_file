// Copyright 2024 - 2024, Kristófer Reykjalín and the log_to_file contributors.
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");
const root = @import("root");

const log_file_path: []const u8 = if (@hasDecl(root, "log_to_file_path"))
    root.log_to_file_path
else
    "log";

pub fn log_to_file(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Get level text and log prefix.
    // See https://ziglang.org/documentation/master/std/#std.log.defaultLog.
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    // Get an allocator to use for getting path to the log file.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            std.log.err("memory leak in custom logger", .{});
        }
    }

    const cwd = std.fs.cwd();

    const log_dir_path = std.fs.path.dirname(log_file_path);
    const log_file_basename = std.fs.path.basename(log_file_path);

    const log_dir = if (log_dir_path) |dir| cwd.makeOpenPath(dir, .{}) catch return else cwd;

    const log = log_dir.createFile(
        log_file_basename,
        .{ .truncate = false },
    ) catch return;

    // Move the write index to the end of the file.
    log.seekFromEnd(0) catch return;

    // Get a writer.
    // See https://ziglang.org/documentation/master/std/#std.log.defaultLog.
    const log_writer = log.writer();
    var bw = std.io.bufferedWriter(log_writer);
    const writer = bw.writer();

    // Write to the log file.
    // See https://ziglang.org/documentation/master/std/#std.log.defaultLog.
    nosuspend {
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}
