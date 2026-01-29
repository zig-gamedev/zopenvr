const std = @import("std");

const openvr = @import("openvr.zig");

function_table: *FunctionTable,

const Self = @This();

const version = "IVRChaperone_004";
pub fn init() openvr.InitError!Self {
    return .{
        .function_table = try openvr.getFunctionTable(FunctionTable, version),
    };
}

pub fn getCalibrationState(self: Self) openvr.CalibrationState {
    return self.function_table.GetCalibrationState();
}

pub fn getPlayAreaSize(self: Self) ?openvr.PlayAreaSize {
    var play_area: openvr.PlayAreaSize = undefined;
    if (self.function_table.GetPlayAreaSize(&play_area.x, &play_area.z)) {
        return play_area;
    } else {
        return null;
    }
}

pub fn getPlayAreaRect(self: Self) ?openvr.Quad {
    var play_area: openvr.Quad = undefined;
    if (self.function_table.GetPlayAreaRect(&play_area)) {
        return play_area;
    } else {
        return null;
    }
}

pub fn reloadInfo(self: Self) void {
    self.function_table.ReloadInfo();
}

pub fn setSceneColor(self: Self, scene_color: openvr.Color) void {
    self.function_table.SetSceneColor(scene_color);
}

pub fn allocBoundsColor(self: Self, allocator: std.mem.Allocator, collision_bounds_fade_distance: f32, bound_colors_count: usize) !openvr.BoundsColor {
    var bounds_color: openvr.BoundsColor = undefined;
    bounds_color.bound_colors = try allocator.alloc(openvr.Color, bound_colors_count);
    self.function_table.GetBoundsColor(bounds_color.bound_colors.ptr, @intCast(bounds_color.bound_colors.len), collision_bounds_fade_distance, &bounds_color.camera_color);
    return bounds_color;
}

pub fn areBoundsVisible(self: Self) bool {
    return self.function_table.AreBoundsVisible();
}

pub fn forceBoundsVisible(self: Self, force: bool) void {
    self.function_table.ForceBoundsVisible(force);
}

pub fn resetZeroPose(self: Self, origin: openvr.TrackingUniverseOrigin) void {
    self.function_table.ResetZeroPose(origin);
}

const FunctionTable = extern struct {
    GetCalibrationState: *const fn () callconv(.c) openvr.CalibrationState,
    GetPlayAreaSize: *const fn (*f32, *f32) callconv(.c) bool,
    GetPlayAreaRect: *const fn (*openvr.Quad) callconv(.c) bool,
    ReloadInfo: *const fn () callconv(.c) void,
    SetSceneColor: *const fn (openvr.Color) callconv(.c) void,
    GetBoundsColor: *const fn ([*c]openvr.Color, c_int, f32, *openvr.Color) callconv(.c) void,
    AreBoundsVisible: *const fn () callconv(.c) bool,
    ForceBoundsVisible: *const fn (bool) callconv(.c) void,
    ResetZeroPose: *const fn (openvr.TrackingUniverseOrigin) callconv(.c) void,
};
