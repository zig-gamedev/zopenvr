const std = @import("std");

const openvr = @import("openvr.zig");

function_table: *FunctionTable,

const Self = @This();
const version = "IVRInput_010";
pub fn init() openvr.InitError!Self {
    return .{
        .function_table = try openvr.getFunctionTable(FunctionTable, version),
    };
}

pub fn setActionManifestPath(self: Self, action_manifest_path: [:0]const u8) openvr.InputError!void {
    const error_code = self.function_table.SetActionManifestPath(@constCast(action_manifest_path.ptr));
    try error_code.maybe();
}

pub fn getActionSetHandle(self: Self, action_set_name: [:0]const u8) openvr.InputError!openvr.ActionSetHandle {
    var result: openvr.ActionSetHandle = undefined;
    const error_code = self.function_table.GetActionSetHandle(@constCast(action_set_name.ptr), &result);
    try error_code.maybe();
    return result;
}
pub fn getActionHandle(self: Self, action_name: [:0]const u8) openvr.InputError!openvr.ActionHandle {
    var result: openvr.ActionHandle = undefined;
    const error_code = self.function_table.GetActionHandle(@constCast(action_name.ptr), &result);
    try error_code.maybe();
    return result;
}
pub fn getInputSourceHandle(self: Self, input_source_path: [:0]const u8) openvr.InputError!openvr.InputValueHandle {
    var result: openvr.InputValueHandle = undefined;
    const error_code = self.function_table.GetInputSourceHandle(@constCast(input_source_path.ptr), &result);
    try error_code.maybe();
    return result;
}

pub fn updateActionState(self: Self, sets: []openvr.ActiveActionSet) openvr.InputError!void {
    const error_code = self.function_table.UpdateActionState(@constCast(sets.ptr), @sizeOf(openvr.ActiveActionSet), @intCast(sets.len));
    try error_code.maybe();
}

pub fn getDigitalActionData(
    self: Self,
    action: openvr.ActionHandle,
    restrict_to_device: openvr.InputValueHandle,
) openvr.InputError!openvr.InputDigitalActionData {
    var result: openvr.InputDigitalActionData = undefined;

    const error_code = self.function_table.GetDigitalActionData(
        action,
        &result,
        @sizeOf(openvr.InputDigitalActionData),
        restrict_to_device,
    );
    try error_code.maybe();

    return result;
}
pub fn getAnalogActionData(
    self: Self,
    action: openvr.ActionHandle,
    restrict_to_device: openvr.InputValueHandle,
) openvr.InputError!openvr.InputAnalogActionData {
    var result: openvr.InputAnalogActionData = undefined;

    const error_code = self.function_table.GetAnalogActionData(
        action,
        &result,
        @sizeOf(openvr.InputAnalogActionData),
        restrict_to_device,
    );
    try error_code.maybe();

    return result;
}

pub fn getPoseActionDataRelativeToNow(
    self: Self,
    action: openvr.ActionHandle,
    origin: openvr.TrackingUniverseOrigin,
    predicted_seconds_from_now: f32,
    restrict_to_device: openvr.InputValueHandle,
) openvr.InputError!openvr.InputPoseActionData {
    var result: openvr.InputPoseActionData = undefined;

    const error_code = self.function_table.GetPoseActionDataRelativeToNow(
        action,
        origin,
        predicted_seconds_from_now,
        &result,
        @sizeOf(openvr.InputPoseActionData),
        restrict_to_device,
    );
    try error_code.maybe();

    return result;
}
pub fn getPoseActionDataForNextFrame(
    self: Self,
    action: openvr.ActionHandle,
    origin: openvr.TrackingUniverseOrigin,
    restrict_to_device: openvr.InputValueHandle,
) openvr.InputError!openvr.InputPoseActionData {
    var result: openvr.InputPoseActionData = undefined;

    const error_code = self.function_table.GetPoseActionDataForNextFrame(
        action,
        origin,
        &result,
        @sizeOf(openvr.InputPoseActionData),
        restrict_to_device,
    );
    try error_code.maybe();

    return result;
}
pub fn getSkeletalActionData(
    self: Self,
    action: openvr.ActionHandle,
) openvr.InputError!openvr.InputSkeletalActionData {
    var result: openvr.InputSkeletalActionData = undefined;

    const error_code = self.function_table.GetSkeletalActionData(
        action,
        &result,
        @sizeOf(openvr.InputSkeletalActionData),
    );
    try error_code.maybe();

    return result;
}
pub fn getDominantHand(
    self: Self,
) openvr.InputError!openvr.TrackedControllerRole {
    var result: openvr.TrackedControllerRole = undefined;

    const error_code = self.function_table.GetDominantHand(
        &result,
    );
    try error_code.maybe();

    return result;
}
pub fn setDominantHand(self: Self, dominant_hand: openvr.TrackedControllerRole) openvr.InputError!void {
    const error_code = self.function_table.SetDominantHand(
        dominant_hand,
    );
    try error_code.maybe();
}
pub fn getBoneCount(
    self: Self,
    action: openvr.ActionHandle,
) openvr.InputError!u32 {
    var result: u32 = undefined;

    const error_code = self.function_table.GetBoneCount(
        action,
        &result,
    );
    try error_code.maybe();

    return result;
}

pub fn allocBoneName(
    self: Self,
    allocator: std.mem.Allocator,
    action: openvr.ActionHandle,
    bone_index: openvr.BoneIndex,
) (openvr.InputError || error{OutOfMemory})![:0]u8 {
    var buffer: [openvr.max_bone_name_length:0]u8 = std.mem.zeroes([openvr.max_bone_name_length:0]u8);

    const error_code = self.function_table.GetBoneName(
        action,
        bone_index,
        &buffer,
        @intCast(openvr.max_bone_name_length),
    );
    try error_code.maybe();

    const buffer_slice = std.mem.sliceTo(&buffer, 0);
    const result = try allocator.allocSentinel(u8, buffer_slice.len, 0);
    std.mem.copyForwards(u8, result, buffer_slice);
    return result;
}

pub fn allocSkeletalReferenceTransforms(
    self: Self,
    allocator: std.mem.Allocator,
    action: openvr.ActionHandle,
    transform_space: openvr.SkeletalTransformSpace,
    reference_pose: openvr.SkeletalReferencePose,
    transform_count: usize,
) (openvr.InputError || error{OutOfMemory})![]openvr.BoneTransform {
    const result = try allocator.alloc(openvr.BoneTransform, transform_count);
    errdefer allocator.free(result);

    if (transform_count > 0) {
        const error_code = self.function_table.GetSkeletalReferenceTransforms(
            action,
            transform_space,
            reference_pose,
            result.ptr,
            @intCast(result.len),
        );
        try error_code.maybe();
    }
    return result;
}

pub fn getSkeletalTrackingLevel(self: Self, action: openvr.ActionHandle) openvr.InputError!openvr.SkeletalTrackingLevel {
    var result: openvr.SkeletalTrackingLevel = undefined;
    const error_code = self.function_table.GetSkeletalTrackingLevel(action, &result);
    try error_code.maybe();
    return result;
}
pub fn allocSkeletalBoneData(
    self: Self,
    allocator: std.mem.Allocator,
    action: openvr.ActionHandle,
    transform_space: openvr.SkeletalTransformSpace,
    motion_range: openvr.SkeletalMotionRange,
    transform_count: usize,
) (openvr.InputError || error{OutOfMemory})![]openvr.BoneTransform {
    const result = try allocator.alloc(openvr.BoneTransform, transform_count);
    errdefer allocator.free(result);

    if (transform_count > 0) {
        const error_code = self.function_table.GetSkeletalBoneData(
            action,
            transform_space,
            motion_range,
            result.ptr,
            @intCast(result.len),
        );
        try error_code.maybe();
    }
    return result;
}
pub fn getSkeletalSummaryData(self: Self, action: openvr.ActionHandle, summary_type: openvr.SummaryType) openvr.InputError!openvr.SkeletalSummaryData {
    var result: openvr.SkeletalSummaryData = undefined;
    const error_code = self.function_table.GetSkeletalSummaryData(action, summary_type, &result);
    try error_code.maybe();
    return result;
}

pub fn allocSkeletalBoneDataCompressed(
    self: Self,
    allocator: std.mem.Allocator,
    action: openvr.ActionHandle,
    motion_range: openvr.SkeletalMotionRange,
) (openvr.InputError || error{OutOfMemory})![]u8 {
    var buffer_length: u32 = 0;
    self.function_table.GetSkeletalBoneDataCompressed(action, motion_range, null, 0, &buffer_length).maybe() catch |err| switch (err) {
        else => return err,
    };
    const result = try allocator.alloc(u8, buffer_length);
    errdefer allocator.free(result);

    if (buffer_length > 0) {
        const error_code = self.function_table.GetSkeletalBoneDataCompressed(
            action,
            motion_range,
            result.ptr,
            @intCast(result.len),
            &buffer_length,
        );
        try error_code.maybe();
    }
    return result;
}

pub fn allocDecompressSkeletalBoneData(
    self: Self,
    allocator: std.mem.Allocator,
    compressed_buffer: []u8,
    transform_space: openvr.SkeletalTransformSpace,
    count: u32,
) (openvr.InputError || error{OutOfMemory})![]openvr.BoneTransform {
    const result = try allocator.alloc(openvr.BoneTransform, count);
    errdefer allocator.free(result);

    if (count > 0) {
        const error_code = self.function_table.DecompressSkeletalBoneData(
            compressed_buffer.ptr,
            @intCast(compressed_buffer.len),
            transform_space,
            result.ptr,
            count,
        );
        try error_code.maybe();
    }
    return result;
}

pub fn triggerHapticVibrationAction(
    self: Self,
    action: openvr.ActionHandle,
    start_seconds_from_now: f32,
    duration_seconds: f32,
    frequency: f32,
    amplitude: f32,
    restrict_to_device: openvr.InputValueHandle,
) openvr.InputError!void {
    const error_code = self.function_table.TriggerHapticVibrationAction(
        action,
        start_seconds_from_now,
        duration_seconds,
        frequency,
        amplitude,
        restrict_to_device,
    );
    try error_code.maybe();
}

pub fn allocActionOrigins(
    self: Self,
    allocator: std.mem.Allocator,
    action_set_handle: openvr.ActionSetHandle,
    digital_action_handle: openvr.ActionHandle,
    count: u32,
) (openvr.InputError || error{OutOfMemory})![]openvr.InputValueHandle {
    const result = try allocator.alloc(openvr.InputValueHandle, count);
    errdefer allocator.free(result);

    if (count > 0) {
        const error_code = self.function_table.GetActionOrigins(
            action_set_handle,
            digital_action_handle,
            result.ptr,
            count,
        );
        try error_code.maybe();
    }
    return result;
}
pub fn allocOriginLocalizedName(
    self: Self,
    allocator: std.mem.Allocator,
    origin: openvr.InputValueHandle,
    string_sections_to_include: i32,
    buffer_length: u32,
) (openvr.InputError || error{OutOfMemory})![:0]u8 {
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }
    const result = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    errdefer allocator.free(result);

    if (buffer_length > 0) {
        const error_code = self.function_table.GetOriginLocalizedName(
            origin,
            result.ptr,
            buffer_length,
            string_sections_to_include,
        );
        try error_code.maybe();
    }
    return result;
}
pub fn getOriginTrackedDeviceInfo(
    self: Self,
    origin: openvr.InputValueHandle,
) openvr.InputError!openvr.InputOriginInfo {
    var result: openvr.InputOriginInfo = undefined;
    const error_code = self.function_table.GetOriginTrackedDeviceInfo(
        origin,
        &result,
        @sizeOf(openvr.InputOriginInfo),
    );
    try error_code.maybe();

    return result;
}

pub fn allocActionBindingInfo(
    self: Self,
    allocator: std.mem.Allocator,
    action: openvr.ActionHandle,
    count: u32,
) (openvr.InputError || error{OutOfMemory})![]openvr.InputBindingInfo {
    var result = try allocator.alloc(openvr.InputBindingInfo, count);
    errdefer allocator.free(result);

    var returned_binding_info_count: u32 = 0;
    if (count > 0) {
        const error_code = self.function_table.GetActionBindingInfo(
            action,
            result.ptr,
            @sizeOf(openvr.InputBindingInfo),
            count,
            &returned_binding_info_count,
        );
        try error_code.maybe();
        result = try allocator.realloc(result, returned_binding_info_count);
    }
    return result;
}
pub fn showActionOrigins(self: Self, action_set_handle: openvr.ActionSetHandle, action_handle: openvr.ActionHandle) openvr.InputError!void {
    const error_code = self.function_table.ShowActionOrigins(
        action_set_handle,
        action_handle,
    );
    try error_code.maybe();
}
pub fn showBindingsForActionSet(self: Self, sets: []const openvr.ActiveActionSet, origin_to_highlight: openvr.InputValueHandle) openvr.InputError!void {
    const error_code = self.function_table.ShowBindingsForActionSet(
        @constCast(sets.ptr),
        @sizeOf(openvr.ActiveActionSet),
        @intCast(sets.len),
        origin_to_highlight,
    );
    try error_code.maybe();
}

pub fn getComponentStateForBinding(
    self: Self,
    render_model_name: [:0]const u8,
    component_name: [:0]const u8,
    origin_info: []const openvr.InputBindingInfo,
) openvr.InputError!openvr.RenderModel.ComponentState {
    var result: openvr.RenderModel.ComponentState = undefined;
    const error_code = self.function_table.GetComponentStateForBinding(
        @constCast(render_model_name.ptr),
        @constCast(component_name.ptr),
        @constCast(origin_info.ptr),
        @sizeOf(openvr.InputBindingInfo),
        @intCast(origin_info.len),
        &result,
    );
    try error_code.maybe();
    return result;
}
pub fn isUsingLegacyInput(self: Self) bool {
    return self.function_table.IsUsingLegacyInput();
}

pub fn openBindingUI(
    self: Self,
    app_key: [:0]const u8,
    action_set_handle: openvr.ActionSetHandle,
    device_handle: openvr.InputValueHandle,
    show_on_desktop: bool,
) openvr.InputError!void {
    const error_code = self.function_table.OpenBindingUI(
        @constCast(app_key.ptr),
        action_set_handle,
        device_handle,
        show_on_desktop,
    );
    try error_code.maybe();
}

pub fn allocBindingVariant(
    self: Self,
    allocator: std.mem.Allocator,
    device_path: openvr.InputValueHandle,
    buffer_length: u32,
) (openvr.InputError || error{OutOfMemory})![:0]u8 {
    if (buffer_length == 0) {
        return allocator.allocSentinel(u8, 0, 0);
    }
    const result = try allocator.allocSentinel(u8, buffer_length - 1, 0);
    errdefer allocator.free(result);

    if (buffer_length > 0) {
        const error_code = self.function_table.GetBindingVariant(
            device_path,
            result.ptr,
            buffer_length,
        );
        try error_code.maybe();
    }
    return result;
}

const FunctionTable = extern struct {
    SetActionManifestPath: *const fn ([*c]u8) callconv(.c) openvr.InputErrorCode,
    GetActionSetHandle: *const fn ([*c]u8, *openvr.ActionSetHandle) callconv(.c) openvr.InputErrorCode,
    GetActionHandle: *const fn ([*c]u8, *openvr.ActionHandle) callconv(.c) openvr.InputErrorCode,
    GetInputSourceHandle: *const fn ([*c]u8, *openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    UpdateActionState: *const fn ([*c]openvr.ActiveActionSet, u32, u32) callconv(.c) openvr.InputErrorCode,
    GetDigitalActionData: *const fn (openvr.ActionHandle, *openvr.InputDigitalActionData, u32, openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    GetAnalogActionData: *const fn (openvr.ActionHandle, *openvr.InputAnalogActionData, u32, openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    GetPoseActionDataRelativeToNow: *const fn (openvr.ActionHandle, openvr.TrackingUniverseOrigin, f32, *openvr.InputPoseActionData, u32, openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    GetPoseActionDataForNextFrame: *const fn (openvr.ActionHandle, openvr.TrackingUniverseOrigin, *openvr.InputPoseActionData, u32, openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    GetSkeletalActionData: *const fn (openvr.ActionHandle, *openvr.InputSkeletalActionData, u32) callconv(.c) openvr.InputErrorCode,
    GetDominantHand: *const fn (*openvr.TrackedControllerRole) callconv(.c) openvr.InputErrorCode,
    SetDominantHand: *const fn (openvr.TrackedControllerRole) callconv(.c) openvr.InputErrorCode,
    GetBoneCount: *const fn (openvr.ActionHandle, *u32) callconv(.c) openvr.InputErrorCode,
    GetBoneHierarchy: *const fn (openvr.ActionHandle, [*c]openvr.BoneIndex, u32) callconv(.c) openvr.InputErrorCode,
    GetBoneName: *const fn (openvr.ActionHandle, openvr.BoneIndex, [*c]u8, u32) callconv(.c) openvr.InputErrorCode,
    GetSkeletalReferenceTransforms: *const fn (openvr.ActionHandle, openvr.SkeletalTransformSpace, openvr.SkeletalReferencePose, [*c]openvr.BoneTransform, u32) callconv(.c) openvr.InputErrorCode,
    GetSkeletalTrackingLevel: *const fn (openvr.ActionHandle, *openvr.SkeletalTrackingLevel) callconv(.c) openvr.InputErrorCode,
    GetSkeletalBoneData: *const fn (openvr.ActionHandle, openvr.SkeletalTransformSpace, openvr.SkeletalMotionRange, [*c]openvr.BoneTransform, u32) callconv(.c) openvr.InputErrorCode,
    GetSkeletalSummaryData: *const fn (openvr.ActionHandle, openvr.SummaryType, *openvr.SkeletalSummaryData) callconv(.c) openvr.InputErrorCode,
    GetSkeletalBoneDataCompressed: *const fn (openvr.ActionHandle, openvr.SkeletalMotionRange, ?*anyopaque, u32, [*c]u32) callconv(.c) openvr.InputErrorCode,
    DecompressSkeletalBoneData: *const fn (?*anyopaque, u32, openvr.SkeletalTransformSpace, [*c]openvr.BoneTransform, u32) callconv(.c) openvr.InputErrorCode,
    TriggerHapticVibrationAction: *const fn (openvr.ActionHandle, f32, f32, f32, f32, openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    GetActionOrigins: *const fn (openvr.ActionSetHandle, openvr.ActionHandle, [*c]openvr.InputValueHandle, u32) callconv(.c) openvr.InputErrorCode,
    GetOriginLocalizedName: *const fn (openvr.InputValueHandle, [*c]u8, u32, i32) callconv(.c) openvr.InputErrorCode,
    GetOriginTrackedDeviceInfo: *const fn (openvr.InputValueHandle, *openvr.InputOriginInfo, u32) callconv(.c) openvr.InputErrorCode,
    GetActionBindingInfo: *const fn (openvr.ActionHandle, [*c]openvr.InputBindingInfo, u32, u32, [*c]u32) callconv(.c) openvr.InputErrorCode,
    ShowActionOrigins: *const fn (openvr.ActionSetHandle, openvr.ActionHandle) callconv(.c) openvr.InputErrorCode,
    ShowBindingsForActionSet: *const fn ([*c]openvr.ActiveActionSet, u32, u32, openvr.InputValueHandle) callconv(.c) openvr.InputErrorCode,
    GetComponentStateForBinding: *const fn ([*c]u8, [*c]u8, [*c]openvr.InputBindingInfo, u32, u32, *openvr.RenderModel.ComponentState) callconv(.c) openvr.InputErrorCode,
    IsUsingLegacyInput: *const fn () callconv(.c) bool,
    OpenBindingUI: *const fn ([*c]u8, openvr.ActionSetHandle, openvr.InputValueHandle, bool) callconv(.c) openvr.InputErrorCode,
    GetBindingVariant: *const fn (openvr.InputValueHandle, [*c]u8, u32) callconv(.c) openvr.InputErrorCode,
};
