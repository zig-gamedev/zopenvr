const std = @import("std");

const openvr = @import("openvr.zig");

function_table: *FunctionTable,

const Self = @This();

const version = "IVRCompositor_028";
pub fn init() openvr.InitError!Self {
    return .{
        .function_table = try openvr.getFunctionTable(FunctionTable, version),
    };
}

pub fn setTrackingSpace(self: Self, origin: openvr.TrackingUniverseOrigin) void {
    self.function_table.SetTrackingSpace(origin);
}

pub fn getTrackingSpace(self: Self) openvr.TrackingUniverseOrigin {
    return self.function_table.GetTrackingSpace();
}

pub fn allocWaitPoses(self: Self, allocator: std.mem.Allocator, render_poses_count: usize, game_poses_count: usize) (openvr.CompositorError || error{OutOfMemory})!openvr.CompositorPoses {
    const poses = try openvr.CompositorPoses.allocInit(allocator, render_poses_count, game_poses_count);
    errdefer poses.deinit(allocator);

    const compositor_error = self.function_table.WaitGetPoses(@ptrCast(poses.render_poses.ptr), @intCast(render_poses_count), @ptrCast(poses.game_poses.ptr), @intCast(game_poses_count));
    try compositor_error.maybe();

    return poses;
}

pub fn allocLastPoses(self: Self, allocator: std.mem.Allocator, render_poses_count: usize, game_poses_count: usize) (openvr.CompositorError || error{OutOfMemory})!openvr.CompositorPoses {
    const poses = try openvr.CompositorPoses.allocInit(allocator, render_poses_count, game_poses_count);
    errdefer poses.deinit(allocator);

    const compositor_error = self.function_table.GetLastPoses(@ptrCast(poses.render_poses.ptr), @intCast(render_poses_count), @ptrCast(poses.game_poses.ptr), @intCast(game_poses_count));
    try compositor_error.maybe();

    return poses;
}

pub fn getLastPoseForTrackedDeviceIndex(self: Self, device_index: openvr.TrackedDeviceIndex) openvr.CompositorError!openvr.CompositorPose {
    var pose: openvr.CompositorPose = undefined;
    const compositor_error = self.function_table.GetLastPoseForTrackedDeviceIndex(device_index, &pose.render_pose, &pose.game_pose);
    try compositor_error.maybe();

    return pose;
}

pub fn getLastRenderPoseForTrackedDeviceIndex(self: Self, device_index: openvr.TrackedDeviceIndex) openvr.CompositorError!openvr.TrackedDevicePose {
    var pose: openvr.TrackedDevicePose = undefined;
    const compositor_error = self.function_table.GetLastPoseForTrackedDeviceIndex(device_index, &pose, null);
    try compositor_error.maybe();

    return pose;
}

pub fn getLastGamePoseForTrackedDeviceIndex(self: Self, device_index: openvr.TrackedDeviceIndex) openvr.CompositorError!openvr.TrackedDevicePose {
    var pose: openvr.TrackedDevicePose = undefined;
    const compositor_error = self.function_table.GetLastPoseForTrackedDeviceIndex(device_index, null, &pose);
    try compositor_error.maybe();

    return pose;
}

pub fn submit(self: Self, eye: openvr.Eye, texture: *const openvr.Texture, texture_bounds: ?openvr.TextureBounds, flags: openvr.SubmitFlags) openvr.CompositorError!void {
    const compositor_error = self.function_table.Submit(eye, texture, if (texture_bounds) |tb| &tb else null, flags);
    try compositor_error.maybe();
}

pub fn submitWithArrayIndex(self: Self, eye: openvr.Eye, textures: [*]openvr.Texture, index: u32, texture_bounds: ?openvr.TextureBounds, flags: openvr.SubmitFlags) openvr.CompositorError!void {
    const compositor_error = self.function_table.SubmitWithArrayIndex(eye, textures, index, if (texture_bounds) |tb| &tb else null, flags);
    try compositor_error.maybe();
}

pub fn clearLastSubmittedFrame(self: Self) void {
    self.function_table.ClearLastSubmittedFrame();
}

pub fn postPresentHandoff(self: Self) void {
    self.function_table.PostPresentHandoff();
}

pub fn getFrameTiming(self: Self, frames_ago: u32) ?openvr.FrameTiming {
    var frame_timing: openvr.FrameTiming = undefined;
    frame_timing.size = @sizeOf(openvr.FrameTiming);
    if (self.function_table.GetFrameTiming(&frame_timing, frames_ago)) {
        return frame_timing;
    } else {
        return null;
    }
}

pub fn allocFrameTimings(self: Self, allocator: std.mem.Allocator, count: u32) ![]openvr.FrameTiming {
    var frame_timings = try allocator.alloc(openvr.FrameTiming, count);
    errdefer allocator.free(frame_timings);

    if (count > 0) {
        frame_timings[0].size = @sizeOf(openvr.FrameTiming);
        const actual_count = self.function_table.GetFrameTimings(frame_timings.ptr, count);
        frame_timings = try allocator.realloc(frame_timings, actual_count);
    }
    return frame_timings;
}

pub fn getFrameTimeRemaining(self: Self) f32 {
    return self.function_table.GetFrameTimeRemaining();
}

pub fn getCumulativeStats(self: Self) openvr.CumulativeStats {
    var cummulative_stats: openvr.CumulativeStats = undefined;
    self.function_table.GetCumulativeStats(&cummulative_stats, @sizeOf(openvr.CumulativeStats));
    return cummulative_stats;
}

pub fn fadeToColor(self: Self, seconds: f32, color: openvr.Color, background: bool) void {
    self.function_table.FadeToColor(seconds, color.r, color.g, color.b, color.a, background);
}

pub fn getCurrentFadeColor(self: Self, background: bool) openvr.Color {
    return self.function_table.GetCurrentFadeColor(background);
}

pub fn fadeGrid(self: Self, seconds: f32, background: bool) void {
    self.function_table.FadeGrid(seconds, background);
}

pub fn getCurrentGridAlpha(self: Self) f32 {
    return self.function_table.GetCurrentGridAlpha();
}

pub fn setSkyboxOverride(self: Self, skybox: openvr.Skybox) openvr.CompositorError!void {
    const textures = skybox.asSlice();
    const compositor_error = self.function_table.SetSkyboxOverride(textures.ptr, textures.len);
    try compositor_error.maybe();
}

pub fn clearSkyboxOverride(self: Self) void {
    self.function_table.ClearSkyboxOverride();
}

pub fn compositorBringToFront(self: Self) void {
    self.function_table.CompositorBringToFront();
}

pub fn compositorGoToBack(self: Self) void {
    self.function_table.CompositorGoToBack();
}

pub fn compositorQuit(self: Self) void {
    self.function_table.CompositorQuit();
}

pub fn isFullscreen(self: Self) bool {
    return self.function_table.IsFullscreen();
}

pub fn getCurrentSceneFocusProcess(self: Self) u32 {
    return self.function_table.GetCurrentSceneFocusProcess();
}

pub fn getLastFrameRenderer(self: Self) u32 {
    return self.function_table.GetLastFrameRenderer();
}

pub fn canRenderScene(self: Self) bool {
    return self.function_table.CanRenderScene();
}

pub fn showMirrorWindow(self: Self) void {
    self.function_table.ShowMirrorWindow();
}

pub fn hideMirrorWindow(self: Self) void {
    self.function_table.HideMirrorWindow();
}

pub fn isMirrorWindowVisible(self: Self) bool {
    return self.function_table.IsMirrorWindowVisible();
}

pub fn compositorDumpImages(self: Self) void {
    self.function_table.CompositorDumpImages();
}

pub fn shouldAppRenderWithLowResources(self: Self) bool {
    return self.function_table.ShouldAppRenderWithLowResources();
}

pub fn forceInterleavedReprojectionOn(self: Self, override: bool) void {
    return self.function_table.ForceInterleavedReprojectionOn(override);
}

pub fn forceReconnectProcess(self: Self) void {
    self.function_table.ForceReconnectProcess();
}

pub fn suspendRendering(self: Self, suspend_rendering: bool) void {
    self.function_table.SuspendRendering(suspend_rendering);
}

pub fn setExplicitTimingMode(self: Self, timing_mode: openvr.TimingMode) void {
    self.function_table.SetExplicitTimingMode(timing_mode);
}

pub fn submitExplicitTimingData(self: Self) openvr.CompositorError!void {
    const compositor_error = self.function_table.SubmitExplicitTimingData();
    try compositor_error.maybe();
}

pub fn isMotionSmoothingEnabled(self: Self) bool {
    return self.function_table.IsMotionSmoothingEnabled();
}

pub fn isMotionSmoothingSupported(self: Self) bool {
    return self.function_table.IsMotionSmoothingSupported();
}

pub fn isCurrentSceneFocusAppLoading(self: Self) bool {
    return self.function_table.IsCurrentSceneFocusAppLoading();
}

pub fn setStageOverrideAsync(self: Self, render_model_path: [:0]const u8, transform: openvr.Matrix34, stage_render_settings: openvr.StageRenderSettings) openvr.CompositorError!void {
    const compositor_error = self.function_table.SetStageOverride_Async(render_model_path.ptr, &transform, &stage_render_settings, @sizeOf(openvr.StageRenderSettings));
    try compositor_error.maybe();
}

pub fn clearStageOverride(self: Self) void {
    self.function_table.ClearStageOverride();
}

pub fn getCompositorBenchmarkResults(self: Self) ?openvr.BenchmarkResults {
    var benchmark_results: openvr.BenchmarkResults = undefined;
    if (self.function_table.GetCompositorBenchmarkResults(&benchmark_results, @sizeOf(openvr.BenchmarkResults))) {
        return benchmark_results;
    } else {
        return null;
    }
}

pub fn getLastPosePredictionIDs(self: Self) openvr.CompositorError!openvr.CompositorPosePredictionIDs {
    var prediction_ids: openvr.CompositorPosePredictionIDs = undefined;
    const compositor_error = self.function_table.GetLastPosePredictionIDs(&prediction_ids.render_pose_prediction_id, &prediction_ids.game_pose_prediction_id);
    try compositor_error.maybe();
    return prediction_ids;
}

pub fn allocPosesForFrame(self: Self, allocator: std.mem.Allocator, pose_prediction_id: u32, pose_count: u32) (openvr.CompositorError || error{OutOfMemory})![]openvr.TrackedDevicePose {
    const poses = try allocator.alloc(openvr.TrackedDevicePose, pose_count);
    const compositor_error = self.function_table.GetPosesForFrame(pose_prediction_id, poses.ptr, pose_count);
    try compositor_error.maybe();
    return poses;
}

const FunctionTable = extern struct {
    SetTrackingSpace: *const fn (openvr.TrackingUniverseOrigin) callconv(.c) void,
    GetTrackingSpace: *const fn () callconv(.c) openvr.TrackingUniverseOrigin,
    WaitGetPoses: *const fn (*openvr.TrackedDevicePose, u32, *openvr.TrackedDevicePose, u32) callconv(.c) openvr.CompositorErrorCode,
    GetLastPoses: *const fn (*openvr.TrackedDevicePose, u32, *openvr.TrackedDevicePose, u32) callconv(.c) openvr.CompositorErrorCode,
    GetLastPoseForTrackedDeviceIndex: *const fn (openvr.TrackedDeviceIndex, *openvr.TrackedDevicePose, *openvr.TrackedDevicePose) callconv(.c) openvr.CompositorErrorCode,
    Submit: *const fn (openvr.Eye, *const openvr.Texture, ?*const openvr.TextureBounds, openvr.SubmitFlags) callconv(.c) openvr.CompositorErrorCode,
    SubmitWithArrayIndex: *const fn (openvr.Eye, [*]openvr.Texture, u32, *openvr.TextureBounds, openvr.SubmitFlags) callconv(.c) openvr.CompositorErrorCode,
    ClearLastSubmittedFrame: *const fn () callconv(.c) void,
    PostPresentHandoff: *const fn () callconv(.c) void,
    GetFrameTiming: *const fn (*openvr.FrameTiming, u32) callconv(.c) bool,
    GetFrameTimings: *const fn ([*c]openvr.FrameTiming, u32) callconv(.c) u32,
    GetFrameTimeRemaining: *const fn () callconv(.c) f32,
    GetCumulativeStats: *const fn (*openvr.CumulativeStats, u32) callconv(.c) void,
    FadeToColor: *const fn (f32, f32, f32, f32, f32, bool) callconv(.c) void,
    GetCurrentFadeColor: *const fn (bool) callconv(.c) openvr.Color,
    FadeGrid: *const fn (f32, bool) callconv(.c) void,
    GetCurrentGridAlpha: *const fn () callconv(.c) f32,
    SetSkyboxOverride: *const fn (*openvr.Texture, u32) callconv(.c) openvr.CompositorErrorCode,
    ClearSkyboxOverride: *const fn () callconv(.c) void,
    CompositorBringToFront: *const fn () callconv(.c) void,
    CompositorGoToBack: *const fn () callconv(.c) void,
    CompositorQuit: *const fn () callconv(.c) void,
    IsFullscreen: *const fn () callconv(.c) bool,
    GetCurrentSceneFocusProcess: *const fn () callconv(.c) u32,
    GetLastFrameRenderer: *const fn () callconv(.c) u32,
    CanRenderScene: *const fn () callconv(.c) bool,
    ShowMirrorWindow: *const fn () callconv(.c) void,
    HideMirrorWindow: *const fn () callconv(.c) void,
    IsMirrorWindowVisible: *const fn () callconv(.c) bool,
    CompositorDumpImages: *const fn () callconv(.c) void,
    ShouldAppRenderWithLowResources: *const fn () callconv(.c) bool,
    ForceInterleavedReprojectionOn: *const fn (bool) callconv(.c) void,
    ForceReconnectProcess: *const fn () callconv(.c) void,
    SuspendRendering: *const fn (bool) callconv(.c) void,

    // skip over d3d11
    GetMirrorTextureD3D11: usize,
    ReleaseMirrorTextureD3D11: usize,

    // skip over opengl
    GetMirrorTextureGL: usize,
    ReleaseSharedGLTexture: usize,
    LockGLSharedTextureForAccess: usize,
    UnlockGLSharedTextureForAccess: usize,

    // skip over vulkan
    GetVulkanInstanceExtensionsRequired: usize,
    GetVulkanDeviceExtensionsRequired: usize,

    SetExplicitTimingMode: *const fn (openvr.TimingMode) callconv(.c) void,
    SubmitExplicitTimingData: *const fn () callconv(.c) openvr.CompositorErrorCode,
    IsMotionSmoothingEnabled: *const fn () callconv(.c) bool,
    IsMotionSmoothingSupported: *const fn () callconv(.c) bool,
    IsCurrentSceneFocusAppLoading: *const fn () callconv(.c) bool,
    SetStageOverride_Async: *const fn ([*c]const u8, *const openvr.Matrix34, *const openvr.StageRenderSettings, u32) callconv(.c) openvr.CompositorErrorCode,
    ClearStageOverride: *const fn () callconv(.c) void,
    GetCompositorBenchmarkResults: *const fn (*openvr.BenchmarkResults, u32) callconv(.c) bool,
    GetLastPosePredictionIDs: *const fn (*u32, *u32) callconv(.c) openvr.CompositorErrorCode,
    GetPosesForFrame: *const fn (u32, [*]openvr.TrackedDevicePose, u32) callconv(.c) openvr.CompositorErrorCode,
};
