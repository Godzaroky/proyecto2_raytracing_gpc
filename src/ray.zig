const Vec3 = @import("vec3.zig").Vec3;
const Material = @import("material.zig").Material;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub inline fn at(self: Ray, t: f32) Vec3 {
        return self.origin.add(self.direction.scale(t));
    }
};

pub const Hit = struct {
    distance: f32,
    point: Vec3,
    normal: Vec3,
    u: f32,
    v: f32,
    material: *const Material,
};
