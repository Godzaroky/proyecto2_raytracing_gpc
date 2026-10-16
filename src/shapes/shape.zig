const Ray = @import("../ray.zig").Ray;
const Hit = @import("../ray.zig").Hit;
const Sphere = @import("sphere.zig").Sphere;
const Cube = @import("cube.zig").Cube;
const Prism = @import("prism.zig").Prism;
const RotatedCube = @import("rotated_cube.zig").RotatedCube;
const Aabb = @import("../aabb.zig").Aabb;

pub const Shape = union(enum) {
    sphere: Sphere,
    cube: Cube,
    prism: Prism,
    rotated_cube: RotatedCube,

    pub fn intersect(self: *const Shape, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        return switch (self.*) {
            inline else => |*shape| shape.intersect(ray, t_min, t_max),
        };
    }

    pub fn bounds(self: *const Shape) Aabb {
        return switch (self.*) {
            inline else => |*shape| shape.bounds(),
        };
    }
};
