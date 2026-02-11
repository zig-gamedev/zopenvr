const std = @import("std");

const openvr = @import("openvr.zig");

function_table: *FunctionTable,

const Self = @This();

const version = "IVRSystem_022";
pub fn init() openvr.InitError!Self {
    return .{
        .function_table = try openvr.getFunctionTable(FunctionTable, version),
    };
}

pub fn getRecommendedRenderTargetSize(self: Self) openvr.RenderTargetSize {
    var render_target_size: openvr.RenderTargetSize = .{ .width = 0, .height = 0 };
    self.function_table.GetRecommendedRenderTargetSize(&render_target_size.width, &render_target_size.height);
    return render_target_size;
}

pub fn getProjectionMatrix(self: Self, eye: openvr.Eye, near: f32, far: f32) openvr.Matrix44 {
    return self.function_table.GetProjectionMatrix(eye, near, far);
}

pub fn getProjectionRaw(self: Self, eye: openvr.Eye) openvr.RawProjection {
    var raw_projection: openvr.RawProjection = undefined;
    self.function_table.GetProjectionRaw(eye, &raw_projection.left, &raw_projection.right, &raw_projection.top, &raw_projection.bottom);
    return raw_projection;
}

pub fn computeDistortion(self: Self, eye: openvr.Eye, u: f32, v: f32) ?openvr.DistortionCoordinates {
    var distortion_coordinates: openvr.DistortionCoordinates = undefined;
    if (self.function_table.ComputeDistortion(eye, u, v, &distortion_coordinates)) {
        return distortion_coordinates;
    } else {
        return null;
    }
}

pub fn getEyeToHeadTransform(self: Self, eye: openvr.Eye) openvr.Matrix34 {
    return self.function_table.GetEyeToHeadTransform(eye);
}

pub fn getTimeSinceLastVsync(self: Self) ?openvr.VSyncTiming {
    var timing: openvr.VSyncTiming = undefined;
    if (self.function_table.GetTimeSinceLastVsync(&timing.seconds_since_last_vsync, &timing.frame_counter)) {
        return timing;
    } else {
        return null;
    }
}

pub fn getDXGIOutputInfo(self: Self) ?i32 {
    var adapter_index: i32 = undefined;
    self.function_table.GetDXGIOutputInfo(&adapter_index);
    if (adapter_index == -1) {
        return null;
    }
    return adapter_index;
}
pub fn isDisplayOnDesktop(self: Self) bool {
    return self.function_table.IsDisplayOnDesktop();
}
pub fn setDisplayVisibility(self: Self, is_visible_on_desktop: bool) bool {
    return self.function_table.SetDisplayVisibility(is_visible_on_desktop);
}

pub fn allocDeviceToAbsoluteTrackingPose(self: Self, allocator: std.mem.Allocator, origin: openvr.TrackingUniverseOrigin, predicted_seconds_to_photons_from_now: f32, count: usize) ![]openvr.TrackedDevicePose {
    const tracked_device_poses = try allocator.alloc(openvr.TrackedDevicePose, count);
    if (count > 0) {
        self.function_table.GetDeviceToAbsoluteTrackingPose(origin, predicted_seconds_to_photons_from_now, tracked_device_poses.ptr, @intCast(tracked_device_poses.len));
    }

    return tracked_device_poses;
}

pub fn getSeatedZeroPoseToStandingAbsoluteTrackingPose(self: Self) openvr.Matrix34 {
    return self.function_table.GetSeatedZeroPoseToStandingAbsoluteTrackingPose();
}
pub fn getRawZeroPoseToStandingAbsoluteTrackingPose(self: Self) openvr.Matrix34 {
    return self.function_table.GetRawZeroPoseToStandingAbsoluteTrackingPose();
}
pub fn getSortedTrackedDeviceIndicesOfClass(self: Self, tracked_device_class: openvr.TrackedDeviceClass, tracked_device_indices: []openvr.TrackedDeviceIndex, relative_to_tracked_device_index: openvr.TrackedDeviceIndex) u32 {
    return self.function_table.GetSortedTrackedDeviceIndicesOfClass(tracked_device_class, tracked_device_indices.ptr, @intCast(tracked_device_indices.len), relative_to_tracked_device_index);
}

pub fn getTrackedDeviceActivityLevel(self: Self, device_index: openvr.TrackedDeviceIndex) openvr.DeviceActivityLevel {
    return self.function_table.GetTrackedDeviceActivityLevel(device_index);
}

pub fn applyTransform(self: Self, tracked_device_pose: openvr.TrackedDevicePose, transform: openvr.Matrix34) openvr.TrackedDevicePose {
    var result: openvr.TrackedDevicePose = undefined;
    self.function_table.ApplyTransform(&result, @constCast(&tracked_device_pose), @constCast(&transform));
    return result;
}

pub fn getTrackedDeviceIndexForControllerRole(self: Self, device_type: openvr.TrackedControllerRole) openvr.TrackedDeviceIndex {
    return self.function_table.GetTrackedDeviceIndexForControllerRole(device_type);
}
pub fn getControllerRoleForTrackedDeviceIndex(self: Self, tracked_device_index: openvr.TrackedDeviceIndex) openvr.TrackedControllerRole {
    return self.function_table.GetControllerRoleForTrackedDeviceIndex(tracked_device_index);
}

pub fn getTrackedDeviceClass(self: Self, device_index: openvr.TrackedDeviceIndex) openvr.TrackedDeviceClass {
    return self.function_table.GetTrackedDeviceClass(device_index);
}

pub fn isTrackedDeviceConnected(self: Self, device_index: openvr.TrackedDeviceIndex) bool {
    return self.function_table.IsTrackedDeviceConnected(device_index);
}

pub fn getTrackedDeviceProperty(self: Self, comptime T: type, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.fromType(T)) openvr.TrackedPropertyError!T {
    var property_error: openvr.TrackedPropertyErrorCode = undefined;
    const result = switch (T) {
        bool => self.function_table.GetBoolTrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), &property_error),
        f32 => self.function_table.GetFloatTrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), &property_error),
        i32 => self.function_table.GetInt32TrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), &property_error),
        u64 => self.function_table.GetUint64TrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), &property_error),
        openvr.Matrix34 => self.function_table.GetMatrix34TrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), &property_error),
        else => @compileError("T must be bool, f32, i32, u64, Matrix34"),
    };
    try property_error.maybe();
    return result;
}

pub fn getTrackedDevicePropertyBool(self: Self, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Bool) openvr.TrackedPropertyError!bool {
    return self.getTrackedDeviceProperty(bool, device_index, property);
}

pub fn getTrackedDevicePropertyF32(self: Self, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.F32) openvr.TrackedPropertyError!f32 {
    return self.getTrackedDeviceProperty(f32, device_index, property);
}

pub fn getTrackedDevicePropertyI32(self: Self, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.I32) openvr.TrackedPropertyError!i32 {
    return self.getTrackedDeviceProperty(i32, device_index, property);
}

pub fn getTrackedDevicePropertyU64(self: Self, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.U64) openvr.TrackedPropertyError!u64 {
    return self.getTrackedDeviceProperty(u64, device_index, property);
}

pub fn getTrackedDevicePropertyMatrix34(self: Self, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Matrix34) openvr.TrackedPropertyError!openvr.Matrix34 {
    return self.getTrackedDeviceProperty(openvr.Matrix34, device_index, property);
}

pub fn allocTrackedDevicePropertyArray(self: Self, comptime T: type, allocator: std.mem.Allocator, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Array.fromType(T)) openvr.TrackedPropertyError![]T {
    var property_error: openvr.TrackedPropertyErrorCode = undefined;
    const buffer_length = self.function_table.GetArrayTrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), openvr.PropertyTypeTagCode.fromType(T), null, 0, &property_error);
    property_error.maybe() catch |err| switch (err) {
        openvr.TrackedPropertyError.BufferTooSmall => {},
        else => return err,
    };
    const buffer = try allocator.alloc(u8, buffer_length);

    if (buffer_length > 0) {
        property_error = undefined;
        _ = self.function_table.GetArrayTrackedDeviceProperty(device_index, @enumFromInt(@intFromEnum(property)), openvr.PropertyTypeTagCode.fromType(T), @ptrCast(buffer.ptr), buffer_length, &property_error);
        try property_error.maybe();
    }

    return @alignCast(std.mem.bytesAsSlice(T, buffer));
}

pub fn allocTrackedDevicePropertyArrayF32(self: Self, allocator: std.mem.Allocator, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Array.F32) openvr.TrackedPropertyError![]f32 {
    return self.allocTrackedDevicePropertyArray(f32, allocator, device_index, property);
}

pub fn allocTrackedDevicePropertyArrayI32(self: Self, allocator: std.mem.Allocator, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Array.I32) openvr.TrackedPropertyError![]i32 {
    return self.allocTrackedDevicePropertyArray(i32, allocator, device_index, property);
}

pub fn allocTrackedDevicePropertyArrayVector4(self: Self, allocator: std.mem.Allocator, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Array.Vector4) openvr.TrackedPropertyError![]openvr.Vector4 {
    return self.allocTrackedDevicePropertyArray(openvr.Vector4, allocator, device_index, property);
}

pub fn allocTrackedDevicePropertyArrayMatrix34(self: Self, allocator: std.mem.Allocator, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.Array.Matrix34) openvr.TrackedPropertyError![]openvr.Matrix34 {
    return self.allocTrackedDevicePropertyArray(openvr.Matrix34, allocator, device_index, property);
}

pub fn allocTrackedDevicePropertyString(self: Self, allocator: std.mem.Allocator, device_index: openvr.TrackedDeviceIndex, property: openvr.TrackedDeviceProperty.String) openvr.TrackedPropertyError![:0]u8 {
    var property_error: openvr.TrackedPropertyErrorCode = undefined;
    const buffer_length = self.function_table.GetStringTrackedDeviceProperty(device_index, property, null, 0, &property_error);
    property_error.maybe() catch |err| switch (err) {
        openvr.TrackedPropertyError.BufferTooSmall => {},
        else => return err,
    };
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        property_error = undefined;
        _ = self.function_table.GetStringTrackedDeviceProperty(device_index, property, buffer.ptr, buffer_length, &property_error);
        try property_error.maybe();
    }
    return buffer;
}

pub fn getPropErrorNameFromEnum(self: Self, property_error: openvr.TrackedPropertyErrorCode) [:0]const u8 {
    return std.mem.span(self.function_table.GetPropErrorNameFromEnum(property_error));
}

pub fn pollNextEvent(self: Self) ?openvr.Event {
    var event: openvr.Event = undefined;
    if (self.function_table.PollNextEvent(&event, @sizeOf(openvr.Event))) {
        return event;
    } else {
        return null;
    }
}

pub fn pollNextEventWithPose(self: Self, origin: openvr.TrackingUniverseOrigin) ?openvr.EventWithPose {
    var event: openvr.Event = undefined;
    var pose: openvr.TrackedDevicePose = undefined;
    if (self.function_table.PollNextEventWithPose(origin, &event, @sizeOf(openvr.Event), &pose)) {
        return .{
            .event = event,
            .pose = pose,
        };
    } else {
        return null;
    }
}

pub fn getEventTypeNameFromEnum(self: Self, event_type: openvr.EventType) [:0]const u8 {
    return std.mem.span(self.function_table.GetEventTypeNameFromEnum(event_type));
}

pub fn getHiddenAreaMesh(self: Self, eye: openvr.Eye, mesh_type: openvr.HiddenAreaMeshType) []const openvr.Vector2 {
    const mesh = self.function_table.GetHiddenAreaMesh(eye, mesh_type);
    return if (mesh.triangle_count == 0)
        &.{}
    else
        mesh.vertex_data[0..mesh.triangle_count * 3];
}

pub fn triggerHapticPulse(self: Self, device_index: openvr.TrackedDeviceIndex, axis_id: u32, duration_microseconds: u16) void {
    self.function_table.TriggerHapticPulse(device_index, axis_id, duration_microseconds);
}

pub fn getControllerState(self: Self, device_index: openvr.TrackedDeviceIndex) ?openvr.ControllerState {
    var controller_state: openvr.ControllerState = undefined;
    if (self.function_table.GetControllerState(device_index, &controller_state, @sizeOf(openvr.ControllerState))) {
        return controller_state;
    } else {
        return null;
    }
}

pub fn getControllerStateWithPose(self: Self, origin: openvr.TrackingUniverseOrigin, device_index: openvr.TrackedDeviceIndex) ?openvr.ControllerStateWithPose {
    var controller_state: openvr.ControllerState = undefined;
    var pose: openvr.TrackedDevicePose = undefined;
    if (self.function_table.GetControllerStateWithPose(origin, device_index, &controller_state, @sizeOf(openvr.ControllerState), &pose)) {
        return .{
            .controller_state = controller_state,
            .pose = pose,
        };
    } else {
        return null;
    }
}
pub fn getButtonIdNameFromEnum(self: Self, button_id: openvr.ButtonId) [:0]const u8 {
    return std.mem.span(self.function_table.GetButtonIdNameFromEnum(button_id));
}
pub fn getControllerAxisTypeNameFromEnum(self: Self, axis_type: openvr.ControllerAxisType) [:0]const u8 {
    return std.mem.span(self.function_table.GetControllerAxisTypeNameFromEnum(axis_type));
}
pub fn isInputAvailable(self: Self) bool {
    return self.function_table.IsInputAvailable();
}
pub fn isSteamVRDrawingControllers(self: Self) bool {
    return self.function_table.IsSteamVRDrawingControllers();
}
pub fn shouldApplicationPause(self: Self) bool {
    return self.function_table.ShouldApplicationPause();
}
pub fn shouldApplicationReduceRenderingWork(self: Self) bool {
    return self.function_table.ShouldApplicationReduceRenderingWork();
}
pub fn performFirmwareUpdate(self: Self, device_index: openvr.TrackedDeviceIndex) openvr.FirmwareError!void {
    const firmware_error = self.function_table.PerformFirmwareUpdate(device_index);
    try firmware_error.maybe();
}
pub fn acknowledgeQuitExiting(self: Self) void {
    self.function_table.AcknowledgeQuit_Exiting();
}

pub fn allocAppContainerFilePaths(self: Self, allocator: std.mem.Allocator) !openvr.FilePaths {
    const buffer_length = self.function_table.GetAppContainerFilePaths(null, 0);
    if (buffer_length == 0) {
        return .{ .buffer = try allocator.allocSentinel(u8, 0, 0) };
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        _ = self.function_table.GetAppContainerFilePaths(buffer.ptr, buffer_length);
    }
    return .{ .buffer = buffer };
}

pub fn getRuntimeVersion(self: Self) [:0]const u8 {
    return std.mem.span(self.function_table.GetRuntimeVersion());
}

const FunctionTable = extern struct {
    GetRecommendedRenderTargetSize: *const fn (*u32, *u32) callconv(.c) void,
    GetProjectionMatrix: *const fn (openvr.Eye, f32, f32) callconv(.c) openvr.Matrix44,
    GetProjectionRaw: *const fn (openvr.Eye, *f32, *f32, *f32, *f32) callconv(.c) void,
    ComputeDistortion: *const fn (openvr.Eye, f32, f32, *openvr.DistortionCoordinates) callconv(.c) bool,
    GetEyeToHeadTransform: *const fn (openvr.Eye) callconv(.c) openvr.Matrix34,
    GetTimeSinceLastVsync: *const fn (*f32, *u64) callconv(.c) bool,
    GetD3D9AdapterIndex: *const fn () callconv(.c) i32,
    GetDXGIOutputInfo: *const fn (*i32) callconv(.c) void,

    // skip vulkan
    GetOutputDevice: usize,

    IsDisplayOnDesktop: *const fn () callconv(.c) bool,
    SetDisplayVisibility: *const fn (bool) callconv(.c) bool,
    GetDeviceToAbsoluteTrackingPose: *const fn (openvr.TrackingUniverseOrigin, f32, [*c]openvr.TrackedDevicePose, u32) callconv(.c) void,
    GetSeatedZeroPoseToStandingAbsoluteTrackingPose: *const fn () callconv(.c) openvr.Matrix34,
    GetRawZeroPoseToStandingAbsoluteTrackingPose: *const fn () callconv(.c) openvr.Matrix34,
    GetSortedTrackedDeviceIndicesOfClass: *const fn (openvr.TrackedDeviceClass, [*c]openvr.TrackedDeviceIndex, u32, openvr.TrackedDeviceIndex) callconv(.c) u32,
    GetTrackedDeviceActivityLevel: *const fn (openvr.TrackedDeviceIndex) callconv(.c) openvr.DeviceActivityLevel,
    ApplyTransform: *const fn (*openvr.TrackedDevicePose, *openvr.TrackedDevicePose, *openvr.Matrix34) callconv(.c) void,
    GetTrackedDeviceIndexForControllerRole: *const fn (openvr.TrackedControllerRole) callconv(.c) openvr.TrackedDeviceIndex,
    GetControllerRoleForTrackedDeviceIndex: *const fn (openvr.TrackedDeviceIndex) callconv(.c) openvr.TrackedControllerRole,
    GetTrackedDeviceClass: *const fn (openvr.TrackedDeviceIndex) callconv(.c) openvr.TrackedDeviceClass,
    IsTrackedDeviceConnected: *const fn (openvr.TrackedDeviceIndex) callconv(.c) bool,
    GetBoolTrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty, *openvr.TrackedPropertyErrorCode) callconv(.c) bool,
    GetFloatTrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty, *openvr.TrackedPropertyErrorCode) callconv(.c) f32,
    GetInt32TrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty, *openvr.TrackedPropertyErrorCode) callconv(.c) i32,
    GetUint64TrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty, *openvr.TrackedPropertyErrorCode) callconv(.c) u64,
    GetMatrix34TrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty, *openvr.TrackedPropertyErrorCode) callconv(.c) openvr.Matrix34,
    GetArrayTrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty, openvr.PropertyTypeTagCode, ?*anyopaque, u32, *openvr.TrackedPropertyErrorCode) callconv(.c) u32,
    GetStringTrackedDeviceProperty: *const fn (openvr.TrackedDeviceIndex, openvr.TrackedDeviceProperty.String, [*c]u8, u32, *openvr.TrackedPropertyErrorCode) callconv(.c) u32,
    GetPropErrorNameFromEnum: *const fn (openvr.TrackedPropertyErrorCode) callconv(.c) [*c]u8,
    PollNextEvent: *const fn (*openvr.Event, u32) callconv(.c) bool,
    PollNextEventWithPose: *const fn (openvr.TrackingUniverseOrigin, *openvr.Event, u32, *openvr.TrackedDevicePose) callconv(.c) bool,
    GetEventTypeNameFromEnum: *const fn (openvr.EventType) callconv(.c) [*c]u8,
    GetHiddenAreaMesh: *const fn (openvr.Eye, openvr.HiddenAreaMeshType) callconv(.c) openvr.HiddenAreaMesh,
    GetControllerState: *const fn (openvr.TrackedDeviceIndex, *openvr.ControllerState, u32) callconv(.c) bool,
    GetControllerStateWithPose: *const fn (openvr.TrackingUniverseOrigin, openvr.TrackedDeviceIndex, *openvr.ControllerState, u32, *openvr.TrackedDevicePose) callconv(.c) bool,
    TriggerHapticPulse: *const fn (openvr.TrackedDeviceIndex, u32, c_ushort) callconv(.c) void,
    GetButtonIdNameFromEnum: *const fn (openvr.ButtonId) callconv(.c) [*c]u8,
    GetControllerAxisTypeNameFromEnum: *const fn (openvr.ControllerAxisType) callconv(.c) [*c]u8,
    IsInputAvailable: *const fn () callconv(.c) bool,
    IsSteamVRDrawingControllers: *const fn () callconv(.c) bool,
    ShouldApplicationPause: *const fn () callconv(.c) bool,
    ShouldApplicationReduceRenderingWork: *const fn () callconv(.c) bool,
    PerformFirmwareUpdate: *const fn (openvr.TrackedDeviceIndex) callconv(.c) openvr.FirmwareErrorCode,
    AcknowledgeQuit_Exiting: *const fn () callconv(.c) void,
    GetAppContainerFilePaths: *const fn ([*c]u8, u32) callconv(.c) u32,
    GetRuntimeVersion: *const fn () callconv(.c) [*c]u8,
};
