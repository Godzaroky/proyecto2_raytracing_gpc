const Vec3 = @import("vec3.zig").Vec3;
const Bvh = @import("bvh.zig").Bvh;
const Light = @import("light.zig").Light;
const TextureSet = @import("texture.zig").TextureSet;
const Skybox = @import("skybox.zig").Skybox;

pub const Scene = struct {
    bvh: *const Bvh,
    lights: []const Light,
    textures: *const TextureSet,
    ambient: Vec3,
    skybox: *const Skybox,
};
