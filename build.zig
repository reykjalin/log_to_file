// Copyright 2024 - 2024, Kristófer Reykjalín and the log_to_file contributors.
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");
const builtin = @import("builtin");

const minimum_zig_version = std.SemanticVersion.parse("0.13.0") catch unreachable;

pub fn build(b: *std.Build) void {
    if (comptime (builtin.zig_version.order(minimum_zig_version) == .lt)) {
        @compileError(std.fmt.comptimePrint(
            \\Your Zig version does not meet the minimum build requirement:
            \\  required Zig version: {[minimum_zig_version]}
            \\  actual   Zig version: {[current_version]}
            \\
        , .{
            .current_version = builtin.zig_version,
            .minimum_zig_version = minimum_zig_version,
        }));
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const strip = b.option(bool, "strip", "Omit debug information");

    _ = b.addModule("log_to_file", .{
        .root_source_file = b.path("src/log_to_file.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });
}
