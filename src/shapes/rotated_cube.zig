const Vec3 = @import("../vec3.zig").Vec3;
const Ray = @import("../ray.zig").Ray;
const Hit = @import("../ray.zig").Hit;
const Material = @import("../material.zig").Material;
const Cube = @import("cube.zig").Cube;
const Aabb = @import("../aabb.zig").Aabb;

// Caja girada alrededor del eje y
pub const RotatedCube = struct {
    local: Cube,
    center: Vec3,
    cos_a: f32,
    sin_a: f32,

    pub fn init(center: Vec3, size: Vec3, angle: f32, material: *const Material) RotatedCube {
        return .{
            .local = Cube.init(Vec3.zero, size, material),
            .center = center,
            .cos_a = @cos(angle),
            .sin_a = @sin(angle),
        };
    }

    pub fn bounds(self: RotatedCube) Aabb {
        const half = self.local.max;
        const c = @abs(self.cos_a);
        const s = @abs(self.sin_a);
        const extent = Vec3.init(half.x * c + half.z * s, half.y, half.x * s + half.z * c);
        return .{ .min = self.center.sub(extent), .max = self.center.add(extent) };
    }

    pub fn intersect(self: RotatedCube, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        const local_ray = Ray{
            .origin = rotateY(ray.origin.sub(self.center), self.cos_a, -self.sin_a),
            .direction = rotateY(ray.direction, self.cos_a, -self.sin_a),
        };
        var hit = self.local.intersect(local_ray, t_min, t_max) orelse return null;
        hit.point = ray.at(hit.distance);
        hit.normal = rotateY(hit.normal, self.cos_a, self.sin_a);
        return hit;
    }
};

fn rotateY(v: Vec3, cos_a: f32, sin_a: f32) Vec3 {
    return .init(
        v.x * cos_a + v.z * sin_a,
        v.y,
        -v.x * sin_a + v.z * cos_a,
    );
}
