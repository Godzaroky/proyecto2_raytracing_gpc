const Vec3 = @import("vec3.zig").Vec3;

pub const Material = struct {
    color: Vec3,
    albedo: f32,
    specular: f32,
    shininess: f32,
    transparency: f32 = 0,
    reflectivity: f32 = 0,
    refractive_index: f32 = 1,
};
