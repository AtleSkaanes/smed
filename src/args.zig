const params = clap.parseParamsComptime(
    \\-h, --help                        Display this help page and exit
    \\-v, --version                     Display this programs version and exit
    \\-o, --output   <file>             Reroute the output from stdout to a file
    \\-l, --log      <loglevel>         Set the loglevel (none, fatal, err, warning, info (default), verbose)
    \\<file>                            The file to evaluate
);

pub const Ctx = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    file: []const u8,
    output: ?[]const u8,
    loglvl: log.LogLevel,

    pub fn deinit(self: Self) void {
        self.allocator.free(self.file);
        if (self.output) |output| {
            self.allocator.free(output);
        }
    }
};

pub const ParseError = error{ParseError} || err.AllocErr;

pub fn parseArgs(allocator: std.mem.Allocator) ParseError!Ctx {
    var diag = clap.Diagnostic{};

    const args = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = allocator,
        .assignment_separators = "=:",
    }) catch |e| {
        const stream = log.LogStream(.err, false);
        try diag.report(stream, e);
        return error.ParseError;
    };

    if (args.args.help >= 1) {
        const writer = std.io.getStdOut().writer();
        writer.print("smed v{s}\n", .{info.version}) catch {};
        clap.help(writer, clap.Help, &params, .{ .spacing_between_parameters = 0 }) catch {};
        std.process.exit(0);
    }

    if (args.args.version >= 1) {
        const writer = std.io.getStdOut().writer();
        writer.print("smed v{s}\n", .{info.version}) catch {};
        std.process.exit(0);
    }

    const file: []const u8 = if (args.positionals[0]) |file| try allocator.dupe(u8, file) else {
        log.write(.err, "No input file\n");
        return error.ParseError;
    };

    const output: ?[]const u8 = if (args.args.output) |output| try allocator.dupe(u8, output) else null;

    const loglvl: log.LogLevel = args.args.log orelse .info;

    return Ctx{
        .allocator = allocator,
        .file = file,
        .output = output,
        .loglvl = loglvl,
    };
}

const parsers = .{
    .file = clap.parsers.string,
    .loglevel = clap.parsers.enumeration(log.LogLevel),
};

const std = @import("std");
const err = @import("err.zig");
const log = @import("log.zig");
const info = @import("info");

const clap = @import("clap");
