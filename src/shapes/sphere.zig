const Vec3 = @import("../vec3.zig").Vec3;
const Ray = @import("../ray.zig").Ray;
const Hit = @import("../ray.zig").Hit;
const Material = @import("../material.zig").Material;

pub const Sphere = struct {
    center: Vec3,
    radius: f32,
    material: *const Material,

    pub fn intersect(self: Sphere, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        const oc = ray.origin.sub(self.center);
        const half_b = ray.direction.dot(oc);
        const c = oc.dot(oc) - self.radius * self.radius;
        const discriminant = half_b * half_b - c;
        if (discriminant < 0) return null;

        const root = @sqrt(discriminant);
        var t = -half_b - root;
        if (t <= t_min or t >= t_max) {
            t = -half_b + root;
            if (t <= t_min or t >= t_max) return null;
        }

        const point = ray.at(t);
        return .{
            .distance = t,
            .point = point,
            .normal = point.sub(self.center).scale(1 / self.radius),
            .material = self.material,
        };
    }
};
