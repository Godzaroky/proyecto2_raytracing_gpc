const Vec3 = @import("vec3.zig").Vec3;

pub const Light = struct {
    position: Vec3,
    color: Vec3,
    intensity: f32,
};
