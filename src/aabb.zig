const Vec3 = @import("vec3.zig").Vec3;

// Caja envolvente alineada a los ejes
pub const Aabb = struct {
    min: Vec3,
    max: Vec3,

    pub const empty = Aabb{
        .min = Vec3.splat(std_inf),
        .max = Vec3.splat(-std_inf),
    };

    pub fn merge(a: Aabb, b: Aabb) Aabb {
        return .{
            .min = .init(@min(a.min.x, b.min.x), @min(a.min.y, b.min.y), @min(a.min.z, b.min.z)),
            .max = .init(@max(a.max.x, b.max.x), @max(a.max.y, b.max.y), @max(a.max.z, b.max.z)),
        };
    }

    pub fn center(self: Aabb) Vec3 {
        return self.min.add(self.max).scale(0.5);
    }

    // Metodo de slabs con la inversa de la direccion ya calculada
    pub inline fn hit(self: Aabb, origin: Vec3, inv_dir: Vec3, t_min: f32, t_max: f32) bool {
        const t0 = self.min.sub(origin).mul(inv_dir);
        const t1 = self.max.sub(origin).mul(inv_dir);
        const t_near = @max(@max(@min(t0.x, t1.x), @min(t0.y, t1.y)), @max(@min(t0.z, t1.z), t_min));
        const t_far = @min(@min(@max(t0.x, t1.x), @max(t0.y, t1.y)), @min(@max(t0.z, t1.z), t_max));
        return t_near <= t_far;
    }
};

const std_inf = @import("std").math.inf(f32);
