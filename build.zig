// Copyright 2024 - 2025, Kristófer Reykjalín and the log_to_file contributors.
// SPDX-License-Identifier: BSD-3-Clause

const std = @import("std");
const builtin = @import("builtin");

const minimum_zig_version = std.SemanticVersion.parse("0.14.0") catch unreachable;

const Example = enum {
    defaults,
    custom_log_file,
    custom_storage_path,
    custom_storage_path_and_log_file,
};

pub fn build(b: *std.Build) void {
    // Enforce minimum zig version.
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

    // TODO: figure out why stripping debug symbols causes an issue.
    // const strip = b.option(bool, "strip", "Strip debug symbols") orelse
    //     if (optimize == .Debug) false else true;

    const ltf = b.addModule("log_to_file", .{
        .root_source_file = b.path("src/log_to_file.zig"),
        .target = target,
        .optimize = optimize,
        // .strip = strip,
    });

    // Add a check for ZLS to build-on-save.
    const ltf_check = b.addModule("log_to_file", .{
        .root_source_file = b.path("src/log_to_file.zig"),
        .target = target,
        .optimize = optimize,
    });
    const check = b.step("check", "Check if log_to_file compiles");
    check.dependsOn(&ltf_check);

    const maybe_example = b.option(Example, "example", "Run an example");
    if (maybe_example) |example| {
        const source_file = switch (example) {
            .defaults => b.path("examples/defaults.zig"),
            .custom_log_file => b.path("examples/custom_log_file.zig"),
            .custom_storage_path => b.path("examples/custom_storage_path.zig"),
            .custom_storage_path_and_log_file => b.path("examples/custom_storage_path_and_log_file.zig"),
        };

        const exe = b.addExecutable(.{
            .name = "example",
            .root_source_file = source_file,
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("log_to_file", ltf);

        b.installArtifact(exe);

        const run_exe = b.addRunArtifact(exe);
        const run_step = b.step("run", "Run an example");
        run_step.dependOn(&run_exe.step);
    }
}
