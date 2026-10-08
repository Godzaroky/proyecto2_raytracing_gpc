const std = @import("std");
const Vec3 = @import("vec3.zig").Vec3;

pub const Camera = struct {
    position: Vec3,
    forward: Vec3,
    right: Vec3,
    up: Vec3,
    fov: f32,

    pub fn lookAt(position: Vec3, target: Vec3, fov: f32) Camera {
        const forward = target.sub(position).normalize();
        const right = Vec3.up.cross(forward).normalize();
        const up = forward.cross(right);
        return .{
            .position = position,
            .forward = forward,
            .right = right,
            .up = up,
            .fov = fov,
        };
    }

    // ndc_x y ndc_y van de -1 a 1
    pub fn rayDirection(self: Camera, ndc_x: f32, ndc_y: f32, aspect_ratio: f32) Vec3 {
        const half_height = @tan(self.fov * 0.5);
        const x = ndc_x * aspect_ratio * half_height;
        const y = ndc_y * half_height;
        return self.right.scale(x)
            .add(self.up.scale(y))
            .add(self.forward)
            .normalize();
    }
};

// camara orbital
pub const OrbitCamera = struct {
    target: Vec3,
    yaw: f32,
    pitch: f32,
    distance: f32,
    auto_rotate: bool = false,

    pub fn toCamera(self: OrbitCamera) Camera {
        var position: Vec3 = undefined;
        position.x = self.target.x + self.distance * @cos(self.pitch) * @sin(self.yaw);
        position.y = self.target.y + self.distance * @sin(self.pitch);
        position.z = self.target.z + self.distance * @cos(self.pitch) * @cos(self.yaw);

        const camera = Camera.lookAt(position, self.target, 90.0 * std.math.pi / 180.0);
        return camera;
    }
};
