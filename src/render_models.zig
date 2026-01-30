const std = @import("std");

const openvr = @import("openvr.zig");

function_table: *FunctionTable,

const Self = @This();
const version = "IVRRenderModels_006";
pub fn init() openvr.InitError!Self {
    return .{
        .function_table = try openvr.getFunctionTable(FunctionTable, version),
    };
}

pub fn loadRenderModel(self: Self, render_model_name: [:0]const u8) openvr.RenderModelError!openvr.RenderModel {
    while (true) : (std.time.sleep(10_000_000)) {
        return self.loadRenderModelAsync(render_model_name) catch |err| switch (err) {
            error.Loading => continue,
            else => return err,
        };
    }
}

pub fn loadRenderModelAsync(self: Self, render_model_name: [:0]const u8) openvr.RenderModelError!openvr.RenderModel {
    var result: *openvr.ExternRenderModel = undefined;

    const error_code = self.function_table.LoadRenderModel_Async(@constCast(render_model_name.ptr), &result);
    try error_code.maybe();

    return openvr.RenderModel.init(result);
}

pub fn freeRenderModel(self: Self, render_model: openvr.RenderModel) void {
    self.function_table.FreeRenderModel(render_model.extern_ptr);
}

pub fn loadTexture(self: Self, texture_id: openvr.TextureID) openvr.RenderModelError!*openvr.RenderModel.TextureMap {
    while (true) : (std.time.sleep(10_000_000)) {
        return self.loadTextureAsync(texture_id) catch |err| switch (err) {
            error.Loading => continue,
            else => return err,
        };
    }
}

pub fn loadTextureAsync(self: Self, texture_id: openvr.TextureID) openvr.RenderModelError!*openvr.RenderModel.TextureMap {
    var result: *openvr.RenderModel.TextureMap = undefined;

    const error_code = self.function_table.LoadTexture_Async(texture_id, &result);
    try error_code.maybe();

    return result;
}

pub fn freeTexture(self: Self, texture: *openvr.RenderModel.TextureMap) void {
    self.function_table.FreeTexture(texture);
}

pub fn allocRenderModelName(self: Self, allocator: std.mem.Allocator, render_model_index: u32) ![:0]u8 {
    const buffer_length = self.function_table.GetRenderModelName(render_model_index, null, 0);
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        _ = self.function_table.GetRenderModelName(render_model_index, buffer.ptr, buffer_length);
    }

    return buffer;
}

pub fn getRenderModelCount(self: Self) u32 {
    return self.function_table.GetRenderModelCount();
}
pub fn getComponentCount(self: Self, render_model_name: [:0]const u8) u32 {
    return self.function_table.GetComponentCount(@constCast(render_model_name.ptr));
}
pub fn allocComponentName(self: Self, allocator: std.mem.Allocator, render_model_name: [:0]const u8, component_index: u32) ![:0]u8 {
    const buffer_length = self.function_table.GetComponentName(@constCast(render_model_name.ptr), component_index, null, 0);
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        _ = self.function_table.GetComponentName(@constCast(render_model_name.ptr), component_index, buffer.ptr, buffer_length);
    }

    return buffer;
}
pub fn getComponentButtonMask(self: Self, render_model_name: [:0]const u8, component_name: [:0]const u8) u64 {
    return self.function_table.GetComponentButtonMask(@constCast(render_model_name.ptr), @constCast(component_name.ptr));
}
pub fn allocComponentRenderModelName(self: Self, allocator: std.mem.Allocator, render_model_name: [:0]const u8, component_name: [:0]const u8) ![:0]u8 {
    const buffer_length = self.function_table.GetComponentRenderModelName(@constCast(render_model_name.ptr), @constCast(component_name.ptr), null, 0);
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    if (buffer_length > 0) {
        _ = self.function_table.GetComponentRenderModelName(@constCast(render_model_name.ptr), @constCast(component_name.ptr), buffer.ptr, buffer_length);
    }

    return buffer;
}

pub fn getComponentStateForDevicePath(self: Self, render_model_name: [:0]const u8, component_name: [:0]const u8, device_path: openvr.InputValueHandle, state: openvr.RenderModel.ControllerModeState) ?openvr.RenderModel.ComponentState {
    var result: openvr.RenderModel.ComponentState = undefined;
    if (self.function_table.GetComponentStateForDevicePath(@constCast(render_model_name.ptr), @constCast(component_name.ptr), device_path, @constCast(&state), &result)) {
        return result;
    }
    return null;
}

pub fn renderModelHasComponent(self: Self, render_model_name: [:0]const u8, component_name: [:0]const u8) bool {
    return self.function_table.RenderModelHasComponent(@constCast(render_model_name.ptr), @constCast(component_name.ptr));
}

pub fn allocRenderModelThumbnailURL(self: Self, allocator: std.mem.Allocator, render_model_name: [:0]const u8) (openvr.RenderModelError || error{OutOfMemory})![:0]u8 {
    var error_code: openvr.RenderModelErrorCode = undefined;
    const buffer_length = self.function_table.GetRenderModelThumbnailURL(@constCast(render_model_name.ptr), null, 0, &error_code);
    error_code.maybe() catch |err| switch (err) {
        openvr.RenderModelError.BufferTooSmall => {},
        else => return err,
    };
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    errdefer allocator.free(buffer);

    if (buffer_length > 0) {
        _ = self.function_table.GetRenderModelThumbnailURL(@constCast(render_model_name.ptr), buffer.ptr, buffer_length, &error_code);
        try error_code.maybe();
    }

    return buffer;
}
pub fn allocRenderModelOriginalPath(self: Self, allocator: std.mem.Allocator, render_model_name: [:0]const u8) (openvr.RenderModelError || error{OutOfMemory})![:0]u8 {
    var error_code: openvr.RenderModelErrorCode = undefined;
    const buffer_length = self.function_table.GetRenderModelOriginalPath(@constCast(render_model_name.ptr), null, 0, &error_code);
    error_code.maybe() catch |err| switch (err) {
        openvr.RenderModelError.BufferTooSmall => {},
        else => return err,
    };
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }

    const buffer = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    errdefer allocator.free(buffer);

    if (buffer_length > 0) {
        _ = self.function_table.GetRenderModelOriginalPath(@constCast(render_model_name.ptr), buffer.ptr, buffer_length, &error_code);
        try error_code.maybe();
    }

    return buffer;
}

pub fn getRenderModelErrorNameFromEnum(self: Self, error_code: openvr.RenderModelErrorCode) [:0]const u8 {
    return std.mem.span(self.function_table.GetRenderModelErrorNameFromEnum(error_code));
}

const FunctionTable = extern struct {
    LoadRenderModel_Async: *const fn ([*c]u8, **openvr.ExternRenderModel) callconv(.c) openvr.RenderModelErrorCode,
    FreeRenderModel: *const fn (*openvr.ExternRenderModel) callconv(.c) void,
    LoadTexture_Async: *const fn (openvr.TextureID, **openvr.RenderModel.TextureMap) callconv(.c) openvr.RenderModelErrorCode,
    FreeTexture: *const fn (*openvr.RenderModel.TextureMap) callconv(.c) void,

    // skip d3d11
    LoadTextureD3D11_Async: *const fn (openvr.TextureID, ?*anyopaque, [*c]?*anyopaque) callconv(.c) openvr.RenderModelErrorCode,
    LoadIntoTextureD3D11_Async: *const fn (openvr.TextureID, ?*anyopaque) callconv(.c) openvr.RenderModelErrorCode,
    FreeTextureD3D11: *const fn (?*anyopaque) callconv(.c) void,

    GetRenderModelName: *const fn (u32, [*c]u8, u32) callconv(.c) u32,
    GetRenderModelCount: *const fn () callconv(.c) u32,
    GetComponentCount: *const fn ([*c]u8) callconv(.c) u32,
    GetComponentName: *const fn ([*c]u8, u32, [*c]u8, u32) callconv(.c) u32,
    GetComponentButtonMask: *const fn ([*c]u8, [*c]u8) callconv(.c) u64,
    GetComponentRenderModelName: *const fn ([*c]u8, [*c]u8, [*c]u8, u32) callconv(.c) u32,
    GetComponentStateForDevicePath: *const fn ([*c]u8, [*c]u8, openvr.InputValueHandle, *openvr.RenderModel.ControllerModeState, *openvr.RenderModel.ComponentState) callconv(.c) bool,

    // deprecated
    GetComponentState: *const fn ([*c]u8, [*c]u8, [*c]openvr.ControllerState, [*c]openvr.RenderModel.ControllerModeState, [*c]openvr.RenderModel.ComponentState) callconv(.c) bool,

    RenderModelHasComponent: *const fn ([*c]u8, [*c]u8) callconv(.c) bool,
    GetRenderModelThumbnailURL: *const fn ([*c]u8, [*c]u8, u32, [*c]openvr.RenderModelErrorCode) callconv(.c) u32,
    GetRenderModelOriginalPath: *const fn ([*c]u8, [*c]u8, u32, [*c]openvr.RenderModelErrorCode) callconv(.c) u32,
    GetRenderModelErrorNameFromEnum: *const fn (openvr.RenderModelErrorCode) callconv(.c) [*c]u8,
};
