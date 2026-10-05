const Vec3 = @import("../vec3.zig").Vec3;
const Ray = @import("../ray.zig").Ray;
const Hit = @import("../ray.zig").Hit;
const Material = @import("../material.zig").Material;

pub const Cube = struct {
    min: Vec3,
    max: Vec3,
    material: *const Material,

    pub fn init(center: Vec3, size: Vec3, material: *const Material) Cube {
        const half = size.scale(0.5);
        return .{
            .min = center.sub(half),
            .max = center.add(half),
            .material = material,
        };
    }

    // Metodo de slabs
    pub fn intersect(self: Cube, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        const inv_dir = Vec3.init(1 / ray.direction.x, 1 / ray.direction.y, 1 / ray.direction.z);
        const t0 = self.min.sub(ray.origin).mul(inv_dir);
        const t1 = self.max.sub(ray.origin).mul(inv_dir);

        const t_near = @max(@max(@min(t0.x, t1.x), @min(t0.y, t1.y)), @min(t0.z, t1.z));
        const t_far = @min(@min(@max(t0.x, t1.x), @max(t0.y, t1.y)), @max(t0.z, t1.z));
        if (t_near > t_far) return null;

        var t = t_near;
        if (t <= t_min) t = t_far;
        if (t <= t_min or t >= t_max) return null;

        const point = ray.at(t);
        const center = self.min.add(self.max).scale(0.5);
        const half = self.max.sub(self.min).scale(0.5);
        const offset = point.sub(center);
        const rel = Vec3.init(offset.x / half.x, offset.y / half.y, offset.z / half.z);
        const local = point.sub(self.min);
        const scale = 1 / self.material.texture_scale;

        var normal: Vec3 = undefined;
        var u: f32 = undefined;
        var v: f32 = undefined;
        if (@abs(rel.x) >= @abs(rel.y) and @abs(rel.x) >= @abs(rel.z)) {
            normal = Vec3.init(if (rel.x > 0) 1 else -1, 0, 0);
            u = local.z;
            v = local.y;
        } else if (@abs(rel.y) >= @abs(rel.z)) {
            normal = Vec3.init(0, if (rel.y > 0) 1 else -1, 0);
            u = local.x;
            v = local.z;
        } else {
            normal = Vec3.init(0, 0, if (rel.z > 0) 1 else -1);
            u = local.x;
            v = local.y;
        }

        return .{
            .distance = t,
            .point = point,
            .normal = normal,
            .u = u * scale,
            .v = v * scale,
            .material = self.material,
        };
    }
};
