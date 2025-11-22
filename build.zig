const std = @import("std");

pub fn build(b: *std.Build) !void {
    checkGitLfsContent() catch {
        try ensureGit(b.allocator);
        try ensureGitLfs(b.allocator, "install");
        try ensureGitLfs(b.allocator, "pull");
        try checkGitLfsContent();
    };

    const zopenvr = b.addModule("root", .{
        .root_source_file = b.path("src/openvr.zig"),
    });

    if (b.lazyDependency("zwindows", .{
        .zxaudio2_debug_layer = b.option(
            bool,
            "zxaudio2_debug_layer",
            "Enable XAudio2 debug layer",
        ) orelse false,
        .zd3d12_debug_layer = b.option(
            bool,
            "zd3d12_debug_layer",
            "Enable DirectX 12 debug layer",
        ) orelse false,
        .zd3d12_gbv = b.option(
            bool,
            "zd3d12_gbv",
            "Enable DirectX 12 GPU-Based Validation (GBV)",
        ) orelse false,
    })) |zwindows| {
        zopenvr.addImport("zwindows", zwindows.module("zwindows"));
    }
}

pub fn addLibraryPathsTo(zopenvr: *std.Build.Dependency, compile_step: *std.Build.Step.Compile) void {
    const target = compile_step.rootModuleTarget();
    switch (target.os.tag) {
        .windows => {
            if (target.cpu.arch.isX86()) {
                compile_step.addLibraryPath(.{ .dependency = .{
                    .dependency = zopenvr,
                    .sub_path = "libs/openvr/lib/win64",
                } });
            }
        },
        .linux => {
            if (target.cpu.arch.isX86()) {
                compile_step.addLibraryPath(.{ .dependency = .{
                    .dependency = zopenvr,
                    .sub_path = "libs/openvr/lib/linux64",
                } });
            }
        },
        else => {},
    }
}

pub fn addRPathsTo(zopenvr: *std.Build.Dependency, compile_step: *std.Build.Step.Compile) void {
    const target = compile_step.rootModuleTarget();
    switch (target.os.tag) {
        .windows => {
            if (target.cpu.arch.isX86()) {
                compile_step.addRPath(.{ .dependency = .{
                    .dependency = zopenvr,
                    .sub_path = "libs/openvr/bin/win64",
                } });
            }
        },
        .linux => {
            if (target.cpu.arch.isX86()) {
                compile_step.addRPath(.{ .dependency = .{
                    .dependency = zopenvr,
                    .sub_path = "libs/openvr/bin/linux64",
                } });
            }
        },
        else => {},
    }
}

pub fn linkOpenVR(compile_step: *std.Build.Step.Compile) void {
    switch (compile_step.rootModuleTarget().os.tag) {
        .windows, .linux => {
            compile_step.linkSystemLibrary("openvr_api");
        },
        else => {},
    }
}

pub fn installOpenVR(
    zopenvr: *std.Build.Dependency,
    step: *std.Build.Step,
    target: std.Target,
    install_dir: std.Build.InstallDir,
) void {
    const b = step.owner;
    switch (target.os.tag) {
        .windows => {
            if (target.cpu.arch.isX86()) {
                step.dependOn(
                    &b.addInstallFileWithDir(
                        .{ .dependency = .{
                            .dependency = zopenvr,
                            .sub_path = "libs/openvr/bin/win64/openvr_api.dll",
                        } },
                        install_dir,
                        "openvr_api.dll",
                    ).step,
                );
            }
        },
        .linux => {
            if (target.cpu.arch.isX86()) {
                step.dependOn(
                    &b.addInstallFileWithDir(
                        .{ .dependency = .{
                            .dependency = zopenvr,
                            .sub_path = "libs/openvr/bin/linux64/libopenvr_api.so",
                        } },
                        install_dir,
                        "libopenvr_api.so.0",
                    ).step,
                );
            }
        },
        else => {},
    }
}

fn ensureGit(allocator: std.mem.Allocator) !void {
    const printErrorMsg = (struct {
        fn impl() void {
            std.log.err("\n" ++
                \\---------------------------------------------------------------------------
                \\
                \\'git version' failed. Is Git not installed?
                \\
                \\---------------------------------------------------------------------------
                \\
            , .{});
        }
    }).impl;
    const argv = &[_][]const u8{ "git", "version" };
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    }) catch { // e.g. FileNotFound
        printErrorMsg();
        return error.GitNotFound;
    };
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.term.Exited != 0) {
        printErrorMsg();
        return error.GitNotFound;
    }
}

fn ensureGitLfs(allocator: std.mem.Allocator, cmd: []const u8) !void {
    const printNoGitLfs = (struct {
        fn impl() void {
            std.log.err("\n" ++
                \\---------------------------------------------------------------------------
                \\
                \\Please install Git LFS (Large File Support) extension and run 'zig build' again.
                \\
                \\For more info about Git LFS see: https://git-lfs.github.com/
                \\
                \\---------------------------------------------------------------------------
                \\
            , .{});
        }
    }).impl;
    const argv = &[_][]const u8{ "git", "lfs", cmd };
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    }) catch { // e.g. FileNotFound
        printNoGitLfs();
        return error.GitLfsNotFound;
    };
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.term.Exited != 0) {
        printNoGitLfs();
        return error.GitLfsNotFound;
    }
}

fn checkGitLfsContent() !void {
    const expected_contents =
        \\DO NOT EDIT OR DELETE
        \\This file is used to check if Git LFS content has been downloaded
    ;
    var buf: [expected_contents.len]u8 = undefined;
    _ = std.fs.cwd().readFile(".lfs-content-token", &buf) catch {
        return error.GitLfsContentTokenNotFound;
    };
    if (!std.mem.eql(u8, expected_contents, &buf)) {
        return error.GitLfsContentCheckFailed;
    }
}
