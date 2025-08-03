const Self = @This();

/// An error detailing what went wrong when evaluating smed code
pub const EvalError = error{
    FailedPrologue,
    FailedUserCode,
    LuaStackError,
    InvalidType,
} || err.AllocErr;

pub const EvalFileError = error{ReadError} || EvalError || std.fs.File.OpenError;

allocator: std.mem.Allocator,
lua: *zlua.Lua,

/// Initializes the lua runtime, and will run the `Smed` lua prologue, so the builtins are ready.
/// Remember to call `.deinit()` after use
pub fn init(allocator: std.mem.Allocator) EvalError!Self {
    var lua = zlua.Lua.init(allocator) catch return error.OutOfMemory;

    lua.openLibs();

    const prologue: [:0]const u8 = @embedFile("lua/prologue.luau");
    lua.doString(prologue) catch {
        printError(lua);
        return error.FailedPrologue;
    };

    return .{
        .allocator = allocator,
        .lua = lua,
    };
}

/// Deinit the `Smed` object
pub fn deinit(self: *Self) void {
    self.lua.deinit();
}

/// Add a new global value under the `Smed` namespace
pub fn addGlobal(self: *Self, value: anytype, ident: []const u8) (error{LuaStackError} || err.AllocErr)!void {
    _ = self.lua.getGlobal("Smed") catch return error.LuaStackError;
    const table_idx = self.lua.getTop();

    self.lua.pushAny(value) catch return error.LuaStackError;

    const name = try self.allocator.dupeZ(u8, ident);
    defer self.allocator.free(name);

    self.lua.setField(table_idx, name);
}

/// Get `Smed.raw_html` after a codeblock has been evaluated.
fn getFinishedHtml(self: *Self, allocator: std.mem.Allocator) EvalError![]u8 {
    _ = self.lua.getGlobal("Smed") catch return error.LuaStackError;
    const table_idx = self.lua.getTop();
    _ = self.lua.getField(table_idx, "raw_html");

    const html = try allocator.dupe(u8, self.lua.toString(self.lua.getTop()) catch return error.InvalidType);

    self.lua.pop(2);

    return html;
}

/// Print the error message from the lua runtime.
fn printError(lua: *zlua.Lua) void {
    const msg = lua.toString(-1) catch unreachable;
    log.print(.err, "{s}\n", .{msg});
}

/// Cleanup the smed object after a codeblock has been evaluated, so its ready for the next one.
pub fn cleanup(self: *Self) EvalError!void {
    _ = self.lua.getGlobal("Smed") catch return error.LuaStackError;
    const table_idx = self.lua.getTop();
    _ = self.lua.getField(table_idx, "raw_html");
    _ = self.lua.pushString("");
    self.lua.setField(table_idx, "raw_html");
}

/// Evaluate a smed string.
/// This will return the evaluated code in an allocated slice, using `smed.allocator`.
/// The caller is responsible for the slice.
pub fn evalStr(self: *Self, buf: []const u8) EvalError![]u8 {
    var result_builder = std.ArrayList(u8).init(self.allocator);
    defer result_builder.deinit();

    var iter: PartIter = .{ .buffer = buf };

    while (iter.next()) |res| {
        try result_builder.appendSlice(res.pre_html);

        const zCode = try self.allocator.dupeZ(u8, std.mem.trim(u8, res.code, " \t\n"));
        defer self.allocator.free(zCode);

        self.lua.doString(zCode) catch {
            printError(self.lua);
            return error.FailedUserCode;
        };

        const raw_html = try self.getFinishedHtml(self.allocator);
        defer self.allocator.free(raw_html);

        try self.cleanup();

        try result_builder.appendSlice(raw_html);
    }
    try result_builder.appendSlice(iter.rest());

    return try result_builder.toOwnedSlice();
}

/// Evaluate a smed file.
/// This will return the evaluated code in an allocated slice, using `smed.allocator`.
/// The caller is responsible for the slice.
pub fn evalFile(self: *Self, path: []const u8) EvalFileError![]u8 {
    const f = try std.fs.cwd().openFile(path, .{});
    defer f.close();

    const str = f.readToEndAlloc(self.allocator, 10_000_000) catch return error.ReadError;
    defer self.allocator.free(str);

    return try self.evalStr(str);
}

/// Run a normal luau string.
/// This will not run `.cleanup()` afterwards, so if you want to clear `Smed.raw_html` after this,
/// then call `.cleanup()` after this function has finished.
pub fn runRawLuauStr(self: *Self, str: []const u8) EvalError!void {
    const zCode = try self.allocator.dupeZ(u8, str);
    defer self.allocator.free(zCode);

    self.lua.doString(zCode) catch {
        printError(self.lua);
        return error.FailedUserCode;
    };
}

/// Run a normal luau file.
/// This will not run `.cleanup()` afterwards, so if you want to clear `Smed.raw_html` after this,
/// then call `.cleanup()` after this function has finished.
pub fn runRawLuauFile(self: *Self, path: []const u8) EvalFileError!void {
    const f = try std.fs.cwd().openFile(path, .{});
    defer f.close();

    const str = f.readToEndAlloc(self.allocator, 10_000_000) catch return error.ReadError;
    defer self.allocator.free(str);

    try self.runRawLuaStr(str);
}

const std = @import("std");
const err = @import("err.zig");
const log = @import("log.zig");
const PartIter = @import("PartIter.zig");

const zlua = @import("zlua");
