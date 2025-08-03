pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const ctx = args.parseArgs(allocator) catch {
        log.write(.fatal, "Failed to parse arguments\n");
    };

    log.setLogLevel(ctx.loglvl);

    var smed = Smed.init(allocator) catch |e| {
        log.print(.fatal, "Failed to initialize lua runtime: {any}\n", .{e});
    };

    smed.addGlobal(.{ .bar = "baz" }, "foo") catch |e| {
        log.print(.fatal, "Failed to add global table to lua runtime: {any}\n", .{e});
    };

    const out = smed.evalFile(ctx.file) catch |e| {
        log.print(.fatal, "Failed to evaluate file at '{s}': {any}\n", .{ ctx.file, e });
    };

    defer allocator.free(out);

    const writer = if (ctx.output) |file| blk: {
        const f = std.fs.cwd().createFile(file, .{}) catch |e| {
            log.print(.fatal, "Failed to open output file at path '{s}': {any}\n", .{ file, e });
        };
        break :blk f.writer();
    } else std.io.getStdOut().writer();

    _ = writer.write(out) catch |e| {
        log.print(.fatal, "Failed to write result: {any}\n", .{e});
    };
}

test "test" {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
const args = @import("args.zig");
const log = @import("log.zig");
const Smed = @import("Smed.zig");
