const std = @import("std");
const rl = @import("raylib");
const OrbitCamera = @import("camera.zig").OrbitCamera;

const turn_speed = 2.0;
const zoom_step = 0.1;
const distance_min = 3.0;
const distance_max = 40.0;
const pitch_min = std.math.degreesToRadians(10.0);
const pitch_max = std.math.degreesToRadians(85.0);
const auto_rotate_speed = 0.5;
const mouse_sensitivity = 0.005;

pub fn handleInput(orbit: *OrbitCamera, dt: f32) bool {
    const previous = orbit.*;

    if (rl.isKeyDown(.w)) orbit.pitch += turn_speed * dt;
    if (rl.isKeyDown(.s)) orbit.pitch -= turn_speed * dt;
    if (rl.isKeyDown(.a)) orbit.yaw -= turn_speed * dt;
    if (rl.isKeyDown(.d)) orbit.yaw += turn_speed * dt;

    const wheel = rl.getMouseWheelMove();
    orbit.distance *= 1 - wheel * zoom_step;

    if (rl.isMouseButtonDown(.left)) {
        const delta = rl.getMouseDelta();
        orbit.yaw += delta.x * mouse_sensitivity;
        orbit.pitch += delta.y * mouse_sensitivity;
    }

    if (rl.isKeyPressed(.space)) orbit.auto_rotate = !orbit.auto_rotate;
    if (orbit.auto_rotate) orbit.yaw += auto_rotate_speed * dt;

    orbit.pitch = std.math.clamp(orbit.pitch, pitch_min, pitch_max);
    orbit.distance = std.math.clamp(orbit.distance, distance_min, distance_max);

    return orbit.yaw != previous.yaw or
        orbit.pitch != previous.pitch or
        orbit.distance != previous.distance;
}
