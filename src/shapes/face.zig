const Vec3 = @import("../vec3.zig").Vec3;
const Ray = @import("../ray.zig").Ray;

pub const FaceKind = enum {
    triangle,
    parallelogram,
};

pub const Face = struct {
    kind: FaceKind,
    v0: Vec3,
    e1: Vec3,
    e2: Vec3,
    normal: Vec3,
    u_axis: Vec3,
    v_axis: Vec3,

    pub fn init(kind: FaceKind, v0: Vec3, e1: Vec3, e2: Vec3) Face {
        const u_axis = e1.normalize();
        const v_axis = e2.sub(u_axis.scale(e2.dot(u_axis))).normalize();
        return .{
            .kind = kind,
            .v0 = v0,
            .e1 = e1,
            .e2 = e2,
            .normal = e1.cross(e2).normalize(),
            .u_axis = u_axis,
            .v_axis = v_axis,
        };
    }

    // Moller-Trumbore
    pub fn intersect(self: Face, ray: Ray, t_min: f32, t_max: f32) ?f32 {
        const p = ray.direction.cross(self.e2);
        const det = self.e1.dot(p);
        if (@abs(det) < 1e-8) return null;

        const inv_det = 1 / det;
        const s = ray.origin.sub(self.v0);

        const u = s.dot(p) * inv_det;
        if (u < 0 or u > 1) return null;

        const q = s.cross(self.e1);
        const v = ray.direction.dot(q) * inv_det;

        const outside = switch (self.kind) {
            .triangle => u + v > 1,
            .parallelogram => v > 1,
        };
        if (v < 0 or outside) return null;

        const t = self.e2.dot(q) * inv_det;
        if (t <= t_min or t >= t_max) return null;
        return t;
    }
};
