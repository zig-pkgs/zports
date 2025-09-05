const std = @import("std");
const mem = std.mem;

const makepkg = @import("makepkg");
const PkgBuild = makepkg.root.PkgBuild;
const common = makepkg.root.common;
const PackageMetadata = common.PackageMetadata;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const makepkg_dep = b.dependency("makepkg", .{
        .target = target,
        .optimize = optimize,
    });

    const pkgbuild_files = try buildPackageList(b, "main");

    for (pkgbuild_files) |package_metadata| {
        const pkgbuild = package_metadata.parsed.pkgbuild;

        const target_arch: common.Arch = .x86_64;

        const build_pkg = makepkg.addBuildPkg(b, .{
            .arch = target_arch,
            .package_metadata = package_metadata,
        });

        const create_pkg = makepkg.addCreatePkg(b, .{
            .arch = target_arch,
            .pkggen_exe = makepkg_dep.artifact("pkggen"),
            .package_metadata = package_metadata,
            .pkg_build_root = build_pkg.getBuildRoot(),
        });
        create_pkg.installPackage();

        const step_desc = b.fmt("Build package '{s}'", .{pkgbuild.pkgname});
        const pkg_step = b.step(pkgbuild.pkgname, step_desc);
        pkg_step.dependOn(&create_pkg.step);
    }
}

fn buildPackageList(b: *std.Build, repo_name: []const u8) ![]const PackageMetadata {
    var pkgbuild_list: std.ArrayList(PackageMetadata) = .{};
    defer pkgbuild_list.deinit(b.allocator);

    var repo_dir = try b.build_root.handle.openDir(repo_name, .{ .iterate = true });
    defer repo_dir.close();

    var walker = try repo_dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        switch (entry.kind) {
            .file => {
                if (!mem.eql(u8, entry.basename, "PKGBUILD.zon")) continue;
                try pkgbuild_list.append(b.allocator, .{
                    .parsed = try parsePkgBuild(b, entry),
                    .source_file = b.path(b.pathJoin(&.{ repo_name, entry.path })),
                });
            },
            else => {},
        }
    }

    return try pkgbuild_list.toOwnedSlice(b.allocator);
}

fn parsePkgBuild(b: *std.Build, entry: std.fs.Dir.Walker.Entry) !PkgBuild.ParseResult {
    var buffer: [8 * 1024]u8 = undefined;
    const file = try entry.dir.openFile(entry.basename, .{});
    defer file.close();

    var pkgbuild_reader = file.reader(&buffer);
    const reader = &pkgbuild_reader.interface;

    return try PkgBuild.parse(b.allocator, reader);
}
