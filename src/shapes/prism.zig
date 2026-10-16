const Vec3 = @import("../vec3.zig").Vec3;
const Ray = @import("../ray.zig").Ray;
const Hit = @import("../ray.zig").Hit;
const Material = @import("../material.zig").Material;
const Face = @import("./face.zig").Face;
const FaceKind = @import("./face.zig").FaceKind;
const Aabb = @import("../aabb.zig").Aabb;

pub const RidgeAxis = enum {
    x,
    z,
};

pub const Prism = struct {
    faces: [5]Face,
    material: *const Material,
    bounds_min: Vec3,
    bounds_max: Vec3,

    pub fn init(base_center: Vec3, width: f32, length: f32, height: f32, ridge: RidgeAxis, material: *const Material) Prism {
        const hw = width / 2;
        const hl = length / 2;
        const y0 = base_center.y;
        const y1 = y0 + height;

        const a = corner(base_center, ridge, -hw, y0, -hl);
        const b = corner(base_center, ridge, hw, y0, -hl);
        const c = corner(base_center, ridge, 0, y1, -hl);
        const a2 = corner(base_center, ridge, -hw, y0, hl);
        const b2 = corner(base_center, ridge, hw, y0, hl);
        const c2 = corner(base_center, ridge, 0, y1, hl);

        const inside = Vec3.init(base_center.x, y0 + height / 3, base_center.z);

        return .{
            .faces = .{
                outwardFace(.triangle, a, b.sub(a), c.sub(a), inside),
                outwardFace(.triangle, a2, b2.sub(a2), c2.sub(a2), inside),
                outwardFace(.parallelogram, a, a2.sub(a), c.sub(a), inside),
                outwardFace(.parallelogram, b, b2.sub(b), c.sub(b), inside),
                outwardFace(.parallelogram, a, b.sub(a), a2.sub(a), inside),
            },
            .material = material,
            .bounds_min = .init(@min(a.x, b2.x), y0, @min(a.z, b2.z)),
            .bounds_max = .init(@max(a.x, b2.x), y1, @max(a.z, b2.z)),
        };
    }

    pub fn bounds(self: Prism) Aabb {
        return .{ .min = self.bounds_min, .max = self.bounds_max };
    }

    pub fn intersect(self: Prism, ray: Ray, t_min: f32, t_max: f32) ?Hit {
        if (!hitsBounds(ray, self.bounds_min, self.bounds_max, t_min, t_max)) return null;

        var nearest = t_max;
        var closest: ?*const Face = null;
        for (&self.faces) |*face| {
            if (face.intersect(ray, t_min, nearest)) |t| {
                nearest = t;
                closest = face;
            }
        }
        const face = closest orelse return null;

        const point = ray.at(nearest);
        const local = point.sub(face.v0);
        const scale = 1 / self.material.texture_scale;
        return .{
            .distance = nearest,
            .point = point,
            .normal = face.normal,
            .u = local.dot(face.u_axis) * scale,
            .v = local.dot(face.v_axis) * scale,
            .material = self.material,
        };
    }
};

fn corner(center: Vec3, ridge: RidgeAxis, across: f32, y: f32, along: f32) Vec3 {
    return switch (ridge) {
        .z => .init(center.x + across, y, center.z + along),
        .x => .init(center.x + along, y, center.z + across),
    };
}

fn outwardFace(kind: FaceKind, v0: Vec3, e1: Vec3, e2: Vec3, inside: Vec3) Face {
    var face = Face.init(kind, v0, e1, e2);
    const share: f32 = switch (kind) {
        .triangle => 1.0 / 3.0,
        .parallelogram => 0.5,
    };
    const face_center = v0.add(e1.add(e2).scale(share));
    if (face.normal.dot(face_center.sub(inside)) < 0) face.normal = face.normal.negate();
    return face;
}

// Caja envolvente, metodo de slabs
fn hitsBounds(ray: Ray, min: Vec3, max: Vec3, t_min: f32, t_max: f32) bool {
    const inv_dir = Vec3.init(1 / ray.direction.x, 1 / ray.direction.y, 1 / ray.direction.z);
    const t0 = min.sub(ray.origin).mul(inv_dir);
    const t1 = max.sub(ray.origin).mul(inv_dir);
    const t_near = @max(@max(@min(t0.x, t1.x), @min(t0.y, t1.y)), @min(t0.z, t1.z));
    const t_far = @min(@min(@max(t0.x, t1.x), @max(t0.y, t1.y)), @max(t0.z, t1.z));
    return t_near <= t_far and t_far > t_min and t_near < t_max;
}
