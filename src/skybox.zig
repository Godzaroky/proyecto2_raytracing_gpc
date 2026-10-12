const Texture = @import("texture.zig").Texture;
const Vec3 = @import("vec3.zig").Vec3;
const std = @import("std");

pub const Skybox = struct {
    texture: Texture,
    rotation: f32 = 0,

    pub fn load(allocator: std.mem.Allocator, path: [:0]const u8) !Skybox {
        const texture = try Texture.load(allocator, path);
        return .{ .texture = texture };
    }

    pub fn deinit(self: Skybox, allocator: std.mem.Allocator) void {
        self.texture.deinit(allocator);
    }

    pub fn sample(self: *const Skybox, direction: Vec3) Vec3 {
        // angulo horizontal
        const horizontal = std.math.atan2(direction.z, direction.x) + self.rotation;
        const u = 0.5 + horizontal / (2 * std.math.pi);

        // angulo vertical
        const y = std.math.clamp(direction.y, -1.0, 1.0);
        const vertical = std.math.asin(y);
        const v = 0.5 + vertical / std.math.pi;

        return self.texture.sample(u, v);
    }
};
