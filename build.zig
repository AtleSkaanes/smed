const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const smed_lib = b.addModule("libsmed", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "smed",
        .root_module = smed_lib,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "smed",
        .root_module = exe_mod,
    });

    const info = b.addOptions();
    info.addOption([]const u8, "version", "0.0.1");

    exe.root_module.addOptions("info", info);

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    const lua_dep = b.dependency("zlua", .{
        .target = target,
        .optimize = optimize,
        .lang = .luau,
        .shared = false,
    });

    exe.root_module.addImport("zlua", lua_dep.module("zlua"));
    lib.root_module.addImport("zlua", lua_dep.module("zlua"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = smed_lib,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
