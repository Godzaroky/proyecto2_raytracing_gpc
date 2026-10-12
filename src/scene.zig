const Vec3 = @import("vec3.zig").Vec3;
const Shape = @import("shapes/shape.zig").Shape;
const Light = @import("light.zig").Light;
const TextureSet = @import("texture.zig").TextureSet;
const Skybox = @import("skybox.zig").Skybox;

pub const Scene = struct {
    shapes: []const Shape,
    lights: []const Light,
    textures: *const TextureSet,
    ambient: Vec3,
    sky_top: Vec3,
    sky_horizon: Vec3,
    skybox: *const Skybox,
};
