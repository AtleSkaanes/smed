fn addGlobals(lua: *Lua) void {
    _ = lua;
    // const Info = struct {
    //     conn: struct {
    //         client_ip: []const u8,
    //         client_port: u16,
    //         server_ip: []const u8,
    //         server_port: u16,
    //     },
    //     request: struct {
    //         query_params: std.StringHashMap([]const u8),
    //         path: []const u8,
    //         full_req: []const u8,
    //         method: []const u8,
    //         headers: std.StringHashMap([]const u8),
    //         body: []const u8,
    //     },
    //     paths: struct {
    //         serve_dir: []const u8,
    //         global_dir: []const u8,
    //         current_file: []const u8,
    //     },
    // };
}

const Self = @This();

pub const Res = struct {
    code: []const u8,
    pre_html: []const u8,
};

buffer: []const u8,
index: usize = 0,

pub fn next(self: *Self) ?Res {
    const starting_idx = self.index;

    var code_start: ?usize = null;

    var prefix: [6]u8 = undefined;
    const correct_prefix: []const u8 = "<smed>";

    var suffix: [7]u8 = undefined;
    const correct_suffix: []const u8 = "</smed>";

    for (self.index..self.buffer.len) |idx| {
        if (code_start) |start| {
            rotateAppend(&suffix, self.buffer[idx]);
            if (std.mem.eql(u8, &suffix, correct_suffix)) {
                self.index = idx + 1;
                return .{
                    .code = self.buffer[start + prefix.len .. idx - suffix.len],
                    .pre_html = self.buffer[starting_idx..start],
                };
            }
        } else {
            rotateAppend(&prefix, self.buffer[idx]);
            if (std.mem.eql(u8, &prefix, correct_prefix)) {
                code_start = idx - prefix.len + 1;
            }
        }
    }
    return null;
}

pub fn rest(self: *const Self) []const u8 {
    return self.buffer[self.index..];
}

/// Append a element to the back, and rotate the list, discarding the first element
/// rotateAppend([a, b, c, d], e) -> [b, c, d, e]
fn rotateAppend(buf: []u8, elem: u8) void {
    if (buf.len < 1)
        return;

    std.mem.copyForwards(u8, buf[0 .. buf.len - 1], buf[1..]);
    buf[buf.len - 1] = elem;
}

const std = @import("std");
const log = @import("log.zig");
const err = @import("err.zig");

const zlua = @import("zlua");
const Lua = zlua.Lua;

test "rotateAppend" {
    const testing = std.testing;

    var str: [4]u8 = .{ 'A', 'B', 'C', 'D' };
    rotateAppend(&str, 'E');

    try testing.expectEqualStrings("BCDE", &str);
}
