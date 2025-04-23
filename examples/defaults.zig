const std = @import("std");
const ltf = @import("log_to_file");

pub const std_options: std.Options = .{
    .logFn = ltf.log_to_file,
};

pub fn main() void {
    std.log.debug("hello world!", .{});
    std.log.info("hello world!", .{});
    std.log.warn("hello world!", .{});
    std.log.err("hello world!", .{});
}
