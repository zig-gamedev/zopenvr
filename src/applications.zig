const std = @import("std");

const openvr = @import("openvr.zig");

function_table: *FunctionTable,

const Self = @This();
const version = "IVRApplications_007";
pub fn init() openvr.InitError!Self {
    return .{
        .function_table = try openvr.getFunctionTable(FunctionTable, version),
    };
}

pub fn addApplicationManifest(self: Self, application_manifest_full_path: [:0]const u8, temporary: bool) openvr.ApplicationError!void {
    const error_code = self.function_table.AddApplicationManifest(@constCast(application_manifest_full_path.ptr), temporary);
    try error_code.maybe();
}

pub fn removeApplicationManifest(self: Self, application_manifest_full_path: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.RemoveApplicationManifest(@constCast(application_manifest_full_path.ptr));
    try error_code.maybe();
}

pub fn isApplicationInstalled(self: Self, app_key: [:0]const u8) bool {
    return self.function_table.IsApplicationInstalled(@constCast(app_key.ptr));
}

pub fn getApplicationCount(self: Self) u32 {
    return self.function_table.GetApplicationCount();
}

pub fn allocApplicationKeyByIndex(self: Self, allocator: std.mem.Allocator, application_index: u32) (openvr.ApplicationError || error{OutOfMemory})![:0]u8 {
    var application_key_buffer: [openvr.max_application_key_length]u8 = undefined;

    const error_code = self.function_table.GetApplicationKeyByIndex(application_index, &application_key_buffer, @intCast(application_key_buffer.len));
    try error_code.maybe();

    const application_key_slice = std.mem.sliceTo(&application_key_buffer, 0);
    const application_key = try allocator.allocSentinel(u8, application_key_slice.len, 0);
    std.mem.copyForwards(u8, application_key, application_key_slice);
    return application_key;
}

pub fn allocApplicationKeyByProcessId(self: Self, allocator: std.mem.Allocator, process_id: u32) (openvr.ApplicationError || error{OutOfMemory})![:0]u8 {
    var application_key_buffer: [openvr.max_application_key_length]u8 = undefined;

    const error_code = self.function_table.GetApplicationKeyByProcessId(process_id, &application_key_buffer, @intCast(application_key_buffer.len));
    try error_code.maybe();

    const application_key_slice = std.mem.sliceTo(&application_key_buffer, 0);
    const application_key = try allocator.allocSentinel(u8, application_key_slice.len, 0);
    std.mem.copyForwards(u8, application_key, application_key_slice);
    return application_key;
}

pub fn launchApplication(self: Self, app_key: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.LaunchApplication(@constCast(app_key.ptr));
    try error_code.maybe();
}

const ExternAppOverrideKeys = extern struct {
    key: [*c]u8,
    value: [*c]u8,
};
pub fn allocLaunchTemplateApplication(self: Self, allocator: std.mem.Allocator, template_app_key: [:0]const u8, new_app_key: [:0]const u8, keys: []openvr.AppOverrideKeys) (openvr.ApplicationError || error{OutOfMemory})!void {
    const extern_keys = try allocator.alloc(ExternAppOverrideKeys, keys.len);
    defer allocator.free(extern_keys);
    for (keys, 0..) |key, i| {
        extern_keys[i] = .{
            .key = key.key.ptr,
            .value = key.value.ptr,
        };
    }
    const error_code = self.function_table.LaunchTemplateApplication(@constCast(template_app_key.ptr), @constCast(new_app_key.ptr), extern_keys.ptr, @intCast(extern_keys.len));
    try error_code.maybe();
}

pub fn launchApplicationFromMimeType(self: Self, mime_type: [:0]const u8, args: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.LaunchApplicationFromMimeType(@constCast(mime_type.ptr), @constCast(args.ptr));
    try error_code.maybe();
}

pub fn launchDashboardOverlay(self: Self, app_key: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.LaunchDashboardOverlay(@constCast(app_key.ptr));
    try error_code.maybe();
}

pub fn cancelApplicationLaunch(self: Self, app_key: [:0]const u8) bool {
    return self.function_table.CancelApplicationLaunch(@constCast(app_key.ptr));
}

pub fn identifyApplication(self: Self, process_id: u32, app_key: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.IdentifyApplication(process_id, @constCast(app_key.ptr));
    try error_code.maybe();
}

pub fn getApplicationProcessId(self: Self, app_key: [:0]const u8) openvr.ApplicationError!u32 {
    return self.function_table.GetApplicationProcessId(@constCast(app_key.ptr));
}

pub fn getApplicationsErrorNameFromEnum(self: Self, error_code: openvr.ApplicationErrorCode) [:0]const u8 {
    return std.mem.span(self.function_table.GetApplicationsErrorNameFromEnum(error_code));
}

pub fn getApplicationProperty(self: Self, comptime T: type, app_key: [:0]const u8, property: openvr.ApplicationProperty.fromType(T)) openvr.ApplicationError!T {
    var error_code: openvr.ApplicationErrorCode = undefined;
    const result = switch (T) {
        bool => self.function_table.GetApplicationPropertyBool(@constCast(app_key.ptr), @enumFromInt(@intFromEnum(property)), &error_code),
        u64 => self.function_table.GetApplicationPropertyUint64(@constCast(app_key.ptr), @enumFromInt(@intFromEnum(property)), &error_code),
        else => @compileError("T must be bool, u64"),
    };
    try error_code.maybe();
    return result;
}

pub fn allocApplicationPropertyString(self: Self, allocator: std.mem.Allocator, app_key: [:0]const u8, property: openvr.ApplicationProperty.String) (openvr.ApplicationError || error{OutOfMemory})![:0]u8 {
    var error_code: openvr.ApplicationErrorCode = undefined;
    const buffer_length = self.function_table.GetApplicationPropertyString(@constCast(app_key.ptr), @enumFromInt(@intFromEnum(property)), null, 0, &error_code);
    try error_code.maybe();
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    errdefer allocator.free(buffer);

    if (buffer_length > 0) {
        error_code = undefined;
        _ = self.function_table.GetApplicationPropertyString(@constCast(app_key.ptr), @enumFromInt(@intFromEnum(property)), buffer.ptr, buffer_length, &error_code);
        try error_code.maybe();
    }

    return buffer;
}

pub fn getApplicationPropertyBool(self: Self, app_key: [:0]const u8, property: openvr.ApplicationProperty.Bool) openvr.ApplicationError!bool {
    return self.getApplicationProperty(bool, app_key, property);
}

pub fn getApplicationPropertyU64(self: Self, app_key: [:0]const u8, property: openvr.ApplicationProperty.U64) openvr.ApplicationError!u64 {
    return self.getApplicationProperty(u64, app_key, property);
}

pub fn setApplicationAutoLaunch(self: Self, app_key: [:0]const u8, auto_launch: bool) openvr.ApplicationError!void {
    const error_code = self.function_table.SetApplicationAutoLaunch(@constCast(app_key.ptr), auto_launch);
    try error_code.maybe();
}

pub fn getApplicationAutoLaunch(self: Self, app_key: [:0]const u8) openvr.ApplicationError!bool {
    return self.function_table.GetApplicationAutoLaunch(@constCast(app_key.ptr));
}

pub fn setDefaultApplicationForMimeType(self: Self, app_key: [:0]const u8, mime_type: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.SetDefaultApplicationForMimeType(@constCast(app_key.ptr), @constCast(mime_type.ptr));
    try error_code.maybe();
}

pub fn allocDefaultApplicationForMimeType(self: Self, allocator: std.mem.Allocator, mime_type: [:0]const u8) !?[:0]u8 {
    var application_key_buffer: [openvr.max_application_key_length:0]u8 = undefined;

    const result = self.function_table.GetDefaultApplicationForMimeType(@constCast(mime_type.ptr), application_key_buffer[0..], @intCast(application_key_buffer.len));
    if (!result) {
        return null;
    }

    const application_key_slice = std.mem.sliceTo(&application_key_buffer, 0);
    const application_key = try allocator.allocSentinel(u8, application_key_slice.len, 0);
    std.mem.copyForwards(u8, application_key, application_key_slice);
    return application_key;
}

pub fn allocApplicationSupportedMimeTypes(self: Self, allocator: std.mem.Allocator, app_key: [:0]const u8, buffer_length: u32) !?openvr.MimeTypes {
    if (buffer_length == 0) {
        return null;
    }
    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    const result = self.function_table.GetApplicationSupportedMimeTypes(@constCast(app_key.ptr), buffer.ptr, buffer_length);
    if (!result) {
        allocator.free(buffer);
        return null;
    }

    return .{ .buffer = buffer };
}

pub fn allocApplicationsThatSupportMimeType(self: Self, allocator: std.mem.Allocator, mime_type: [:0]const u8) !openvr.AppKeys {
    const buffer_length = self.function_table.GetApplicationsThatSupportMimeType(@constCast(mime_type.ptr), null, 0);
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        _ = self.function_table.GetApplicationsThatSupportMimeType(@constCast(mime_type.ptr), buffer.ptr, buffer_length);
    }

    return .{ .buffer = buffer };
}

pub fn allocApplicationLaunchArguments(self: Self, allocator: std.mem.Allocator, handle: u32) ![:0]u8 {
    const buffer_length = self.function_table.GetApplicationLaunchArguments(handle, null, 0);
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        _ = self.function_table.GetApplicationLaunchArguments(handle, buffer.ptr, buffer_length);
    }

    return buffer;
}

pub fn allocStartingApplication(self: Self, allocator: std.mem.Allocator) (openvr.ApplicationError || error{OutOfMemory})![:0]u8 {
    var application_key_buffer: [openvr.max_application_key_length]u8 = undefined;

    const error_code = self.function_table.GetStartingApplication(&application_key_buffer, @intCast(application_key_buffer.len));
    try error_code.maybe();

    const application_key_slice = std.mem.sliceTo(&application_key_buffer, 0);
    const application_key = try allocator.allocSentinel(u8, application_key_slice.len, 0);
    std.mem.copyForwards(u8, application_key, application_key_slice);
    return application_key;
}

pub fn getSceneApplicationState(self: Self) openvr.SceneApplicationState {
    return self.function_table.GetSceneApplicationState();
}

pub fn performApplicationPrelaunchCheck(self: Self, app_key: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.PerformApplicationPrelaunchCheck(@constCast(app_key.ptr));
    try error_code.maybe();
}

pub fn getSceneApplicationStateNameFromEnum(self: Self, state: openvr.SceneApplicationState) [:0]const u8 {
    return std.mem.span(self.function_table.GetSceneApplicationStateNameFromEnum(state));
}

pub fn launchInternalProcess(self: Self, binary_path: [:0]const u8, arguments: [:0]const u8, working_directory: [:0]const u8) openvr.ApplicationError!void {
    const error_code = self.function_table.LaunchInternalProcess(@constCast(binary_path.ptr), @constCast(arguments.ptr), @constCast(working_directory.ptr));
    try error_code.maybe();
}

pub fn getCurrentSceneProcessId(self: Self) u32 {
    return self.function_table.GetCurrentSceneProcessId();
}

const FunctionTable = extern struct {
    AddApplicationManifest: *const fn ([*c]u8, bool) callconv(.c) openvr.ApplicationErrorCode,
    RemoveApplicationManifest: *const fn ([*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    IsApplicationInstalled: *const fn ([*c]u8) callconv(.c) bool,
    GetApplicationCount: *const fn () callconv(.c) u32,
    GetApplicationKeyByIndex: *const fn (u32, [*c]u8, u32) callconv(.c) openvr.ApplicationErrorCode,
    GetApplicationKeyByProcessId: *const fn (u32, [*c]u8, u32) callconv(.c) openvr.ApplicationErrorCode,
    LaunchApplication: *const fn ([*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    LaunchTemplateApplication: *const fn ([*c]u8, [*c]u8, [*c]ExternAppOverrideKeys, u32) callconv(.c) openvr.ApplicationErrorCode,
    LaunchApplicationFromMimeType: *const fn ([*c]u8, [*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    LaunchDashboardOverlay: *const fn ([*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    CancelApplicationLaunch: *const fn ([*c]u8) callconv(.c) bool,
    IdentifyApplication: *const fn (u32, [*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    GetApplicationProcessId: *const fn ([*c]u8) callconv(.c) u32,
    GetApplicationsErrorNameFromEnum: *const fn (openvr.ApplicationErrorCode) callconv(.c) [*c]u8,
    GetApplicationPropertyString: *const fn ([*c]u8, openvr.ApplicationProperty, [*c]u8, u32, *openvr.ApplicationErrorCode) callconv(.c) u32,
    GetApplicationPropertyBool: *const fn ([*c]u8, openvr.ApplicationProperty, *openvr.ApplicationErrorCode) callconv(.c) bool,
    GetApplicationPropertyUint64: *const fn ([*c]u8, openvr.ApplicationProperty, *openvr.ApplicationErrorCode) callconv(.c) u64,
    SetApplicationAutoLaunch: *const fn ([*c]u8, bool) callconv(.c) openvr.ApplicationErrorCode,
    GetApplicationAutoLaunch: *const fn ([*c]u8) callconv(.c) bool,
    SetDefaultApplicationForMimeType: *const fn ([*c]u8, [*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    GetDefaultApplicationForMimeType: *const fn ([*c]u8, [*c]u8, u32) callconv(.c) bool,
    GetApplicationSupportedMimeTypes: *const fn ([*c]u8, [*c]u8, u32) callconv(.c) bool,
    GetApplicationsThatSupportMimeType: *const fn ([*c]u8, [*c]u8, u32) callconv(.c) u32,
    GetApplicationLaunchArguments: *const fn (u32, [*c]u8, u32) callconv(.c) u32,
    GetStartingApplication: *const fn ([*c]u8, u32) callconv(.c) openvr.ApplicationErrorCode,
    GetSceneApplicationState: *const fn () callconv(.c) openvr.SceneApplicationState,
    PerformApplicationPrelaunchCheck: *const fn ([*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    GetSceneApplicationStateNameFromEnum: *const fn (openvr.SceneApplicationState) callconv(.c) [*c]u8,
    LaunchInternalProcess: *const fn ([*c]u8, [*c]u8, [*c]u8) callconv(.c) openvr.ApplicationErrorCode,
    GetCurrentSceneProcessId: *const fn () callconv(.c) u32,
};
