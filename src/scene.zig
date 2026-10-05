const Vec3 = @import("vec3.zig").Vec3;
const Shape = @import("shapes/shape.zig").Shape;
const Light = @import("light.zig").Light;

pub const Scene = struct {
    shapes: []const Shape,
    lights: []const Light,
    ambient: Vec3,
    sky_top: Vec3,
    sky_horizon: Vec3,
};
