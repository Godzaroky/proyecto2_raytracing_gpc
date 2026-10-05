const Vec3 = @import("vec3.zig").Vec3;
const TextureId = @import("texture.zig").TextureId;

pub const Material = struct {
    color: Vec3 = Vec3.one,
    texture: ?TextureId = null,
    // Unidades de mundo que cubre una repeticion de la textura
    texture_scale: f32 = 1,
    albedo: f32,
    specular: f32,
    shininess: f32,
    transparency: f32 = 0,
    reflectivity: f32 = 0,
    refractive_index: f32 = 1,
};
