# [zopenvr](https://github.com/zig-gamedev/zopenvr)

Zig build package and bindings for [OpenVR](https://github.com/ValveSoftware/openvr) v2.2.3

Work in progress
| Interface       |       Status        |
| --------------- | :-----------------: |
| Applications    |         ✅          |
| BlockQueue      |                     |
| Chaperone       |         ✅          |
| ChaperoneSetup  |                     |
| Compositor      | ✅<br/>(d3d12 only) |
| Debug           |                     |
| DriverManager   |                     |
| ExtendedDisplay |                     |
| HeadsetView     |                     |
| Input           |         ✅          |
| IOBuffer        |                     |
| Notifications   |                     |
| Overlay         |                     |
| OverlayView     |                     |
| Paths           |                     |
| Properties      |                     |
| RenderModels    |         ✅          |
| Resources       |                     |
| Screenshots     |                     |
| Settings        |                     |
| SpatialAnchors  |                     |
| System          |         ✅          |
| TrackedCamera   |                     |


## Getting started

Example `build.zig`:

```zig
pub fn build(b: *std.Build) !void {
    const exe = b.addExecutable(.{ ... });

    const zopenvr = b.dependency("zopenvr", .{});

    exe.root_module.addImport("zopenvr", zopenvr.module("zopenvr"));

    try @import("zopenvr").addLibraryPathsTo(zopenvr, exe);
    try @import("zopenvr").installOpenVR(zopenvr, &exe.step, target.result, .bin);
    @import("zopenvr").linkOpenVR(exe);
}
```

Now in your code you may import and use `zopenvr`:

```zig
const std = @import("std");
const OpenVR = @import("zopenvr");

pub fn main() !void {
    ...

    const openvr = try OpenVR.init(.scene);
    defer openvr.deinit();

    const system = try openvr.system();

    const name = try app.system.allocTrackedDevicePropertyString(allocator, OpenVR.hmd, .tracking_system_name);
    defer allocator.free(name);

    ...
}
```

