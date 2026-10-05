const Ray = @import("../ray.zig").Ray;
const Hit = @import("../ray.zig").Hit;
const Sphere = @import("sphere.zig").Sphere;

pub const Shape = union(enum) {
    sphere: Sphere,

    pub fn intersect(self: Shape, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        return switch (self) {
            inline else => |shape| shape.intersect(ray, t_min, t_max),
        };
    }
};
