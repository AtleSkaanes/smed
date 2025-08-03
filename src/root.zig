test "test" {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
pub const setLogLevel = @import("log.zig").setLogLevel;
const PartIter = @import("PartIter.zig");
pub const Smed = @import("Smed.zig");
